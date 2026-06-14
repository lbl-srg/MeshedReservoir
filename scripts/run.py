#!/usr/bin/env python3
"""
Simulation and post-processing script for MeshedReservoir models using BuildingsPy.
"""

import os
import sys
import argparse
import yaml
import shutil
from pathlib import Path
import multiprocessing as mp

# Get the directory where this script is located
SCRIPT_DIR = Path(__file__).parent.absolute()
PROJECT_DIR = SCRIPT_DIR.parent
OUT_DIR = PROJECT_DIR / "out"
SIM_DIR = OUT_DIR / "simulations"
YAML_FILE = SCRIPT_DIR / "simulation_cases.yaml"


def mat_name(case_index, params):
    """
    Generate the .mat filename based on parameter settings.

    Args:
        case_index: Index of the case
        params: Dictionary with conInd and loop parameters

    Returns:
        str: Filename for the .mat file
    """
    # Extract configuration index (1: highPressure, 2: idealPressure, 3: lowPressure)
    conInd = params['conInd']

    # Map conInd to filename prefix
    if conInd == 1:
        config = "high"
    elif conInd == 2:
        config = "ideal"
    else:  # conInd == 3
        config = "low"

    filename = f"ThreeLoops_{config}_case{case_index}.mat"
    return filename


def check_simulation_completion(mat_file, expected_stop_time, tolerance=1e-6):
    """
    Check if simulation completed successfully by verifying final time.

    Args:
        mat_file: Path to .mat file
        expected_stop_time: Expected final time
        tolerance: Tolerance for comparison

    Returns:
        tuple: (success, final_time, error_message)
    """
    try:
        from buildingspy.io.outputfile import Reader

        r = Reader(str(mat_file), "dymola")
        time = r.values("loo1.pExp")[0]
        final_time = time[-1]

        if abs(final_time - expected_stop_time) > tolerance:
            error_msg = f"Simulation failed: {mat_file.name} - Final time {final_time} != {expected_stop_time}"
            return False, final_time, error_msg

        return True, final_time, None

    except Exception as e:
        error_msg = f"Error reading {mat_file.name}: {str(e)}"
        return False, None, error_msg


def simulate_case(args):
    """
    Simulate a single case (for parallel execution).

    Args:
        args: Tuple of (case_index, case_data, settings, base_sim_dir, tool)

    Returns:
        tuple: (success, mat_file_path, error_message)
    """
    case_index, case_data, settings, base_sim_dir, tool = args

    # Import the correct Simulator class based on tool
    if tool == "dymola":
        from buildingspy.simulate.Dymola import Simulator
    else:
        from buildingspy.simulate.OpenModelica import Simulator

    model_name = settings['model_name']

    # Get the case name (mat filename without extension)
    case_name = mat_name(case_index, case_data['parameters']).replace('.mat', '')

    # Create case-specific directory
    case_dir = base_sim_dir / case_name
    case_dir.mkdir(parents=True, exist_ok=True)

    # Mat file will be in the case directory
    mat_file = case_dir / f"{case_name}.mat"

    try:
        # Create simulator with case-specific output directory
        s = Simulator(model_name, outputDirectory=str(case_dir))

        # Set simulation parameters
        s.setStartTime(settings['startTime'])
        s.setStopTime(settings['stopTime'])
        s.setSolver(settings['solver'])
        s.setTolerance(settings['tolerance'])
        s.setNumberOfIntervals(settings['numberOfIntervals'])
        s.setResultFile(f"{case_name}")

        # Set all top-level scalar parameters (those whose value is not a sub-dict)
        for param_name, param_value in case_data['parameters'].items():
            if not isinstance(param_value, dict):
                s.addParameters({param_name: param_value})

        # Set parameters for each loop
        for loop_name in ['loo1', 'loo2', 'loo3']:
            if loop_name in case_data['parameters']:
                loop_params = case_data['parameters'][loop_name]
                for param_name, param_value in loop_params.items():
                    full_param_name = f"{loop_name}.{param_name}"
                    s.addParameters({full_param_name: param_value})

        # Run simulation
        print(f"Simulating case {case_index}: {case_data['label']}")
        s.showGUI(False)
        s.exitSimulator(True)
        s.simulate()

        # Check if simulation completed
        success, final_time, error_msg = check_simulation_completion(mat_file, settings['stopTime'])

        if not success:
            return False, mat_file, error_msg

        print(f"Completed case {case_index}: {case_data['label']}")
        return True, mat_file, None

    except Exception as e:
        error_msg = f"Error simulating case {case_index}: {str(e)}"
        return False, mat_file, error_msg


def simulate(n_processors=1, tool="dymola"):
    """
    Run simulations for all cases defined in YAML file.

    Args:
        n_processors: Number of processors for parallel execution
        tool: Simulation tool ("dymola" or "openmodelica")
    """
    print(f"\n{'='*60}")
    print(f"SIMULATION")
    print(f"{'='*60}\n")

    # Load YAML configuration
    with open(YAML_FILE, 'r') as f:
        config = yaml.safe_load(f)

    settings = config['simulation_settings']
    cases = config['cases']

    # Delete and recreate simulation directory
    if SIM_DIR.exists():
        print(f"Deleting existing simulation directory: {SIM_DIR}")
        shutil.rmtree(SIM_DIR)

    # Create directories
    OUT_DIR.mkdir(exist_ok=True)
    SIM_DIR.mkdir(exist_ok=True)
    print(f"Created output directory: {SIM_DIR}\n")

    # Prepare arguments for simulation
    sim_args = [
        (i, case_data, settings, SIM_DIR, tool)
        for i, case_data in enumerate(cases)
    ]

    # Run simulations
    # Ensure simulation directory exists
    SIM_DIR.mkdir(parents=True, exist_ok=True)

    if n_processors == 1:
        print(f"Running simulations sequentially...\n")
        results = [simulate_case(arg) for arg in sim_args]
    else:
        print(f"Running simulations in parallel with {n_processors} processors...\n")
        with mp.Pool(processes=n_processors) as pool:
            results = pool.map(simulate_case, sim_args)

    # Check results
    all_success = True
    for success, mat_file, error_msg in results:
        if not success:
            print(f"ERROR: {error_msg}")
            all_success = False

    if not all_success:
        print("\n" + "="*60)
        print("SIMULATION FAILED - See errors above")
        print("="*60)
        sys.exit(1)

    # Clean up auxiliary files from case directories
    print("\nCleaning up auxiliary files...")
    cleanup_patterns = ['dsin.txt', 'dsmodel.txt', 'dymosim', 'dsfinal.txt']
    for pattern in cleanup_patterns:
        # Search recursively in case subdirectories
        for file in SIM_DIR.glob(f"*/{pattern}"):
            file.unlink()
            print(f"  Deleted: {file.parent.name}/{file.name}")

    print("\n" + "="*60)
    print("SIMULATION COMPLETED SUCCESSFULLY")
    print("="*60 + "\n")


def postprocess():
    """
    Post-process simulation results and create plots.
    """
    import matplotlib.pyplot as plt
    import numpy as np

    print(f"\n{'='*60}")
    print(f"POST-PROCESSING")
    print(f"{'='*60}\n")

    # Delete existing plots in out directory (not subdirectories)
    print("Deleting existing plots in out directory...")
    for ext in ['*.pdf', '*.png']:
        for file in OUT_DIR.glob(ext):
            file.unlink()
            print(f"  Deleted: {file.name}")

    # Load YAML configuration
    with open(YAML_FILE, 'r') as f:
        config = yaml.safe_load(f)

    settings = config['simulation_settings']
    cases = config['cases']

    # Import Reader for reading .mat files
    from buildingspy.io.outputfile import Reader

    # Read all simulation results
    print("\nReading simulation results...")
    results = []
    for i, case_data in enumerate(cases):
        # Get the case name (mat filename without extension)
        case_name = mat_name(i, case_data['parameters']).replace('.mat', '')

        # Mat file is in case-specific directory
        mat_file = SIM_DIR / case_name / f"{case_name}.mat"

        if not mat_file.exists():
            print(f"ERROR: Expected output file not found: {mat_file}")
            sys.exit(1)

        # Check simulation completion
        success, final_time, error_msg = check_simulation_completion(mat_file, settings['stopTime'])
        if not success:
            print(f"ERROR: {error_msg}")
            sys.exit(1)

        # Read data
        r = Reader(str(mat_file), "dymola")

        data = {
            'label': case_data['label'],
            'time': r.values("loo1.pExp")[0],
            'loo1_pExp': r.values("loo1.pExp")[1],
            'loo2_pExp': r.values("loo2.pExp")[1],
            'loo3_pExp': r.values("loo3.pExp")[1],
            'yPum_y1': r.values("loo1.yPum.y[1]")[1],
            'yPum_y2': r.values("loo2.yPum.y[1]")[1],
            'yPum_y3': r.values("loo3.yPum.y[1]")[1],
            'pSysMax': r.values("pSysMax.y")[1],
            'pSysMin': r.values("pSysMin.y")[1],
        }

        # Read interloop heat transfer variables; interpolate onto common time grid
        common_time = data['time']
        try:
            t, v = r.values("loo1.ySetWasHea")
            data['loo1.ySetWasHea'] = np.interp(common_time, t, v)
            t, v = r.values("loo2.ySetWasHea")
            data['loo2.ySetWasHea'] = np.interp(common_time, t, v)
            t, v = r.values("loo1.vol.T")
            data['loo1.vol.T'] = np.interp(common_time, t, v)
            t, v = r.values("loo2.vol.T")
            data['loo2.vol.T'] = np.interp(common_time, t, v)
            t, v = r.values("loo3.vol.T")
            data['loo3.vol.T'] = np.interp(common_time, t, v)
        except Exception:
            pass

        # Get m_flow_nominal from first case
        if i == 0:
            m_flow_nominal = r.values("m_flow_nominal")[1][0]
            data['m_flow_nominal'] = m_flow_nominal

        results.append(data)
        print(f"  Read case {i}: {case_data['label']}")

    # Set m_flow_nominal
    m_flow_nominal = results[0]['m_flow_nominal']
    print(f"\nm_flow_nominal = {m_flow_nominal}")

    # Calculate pMin and pMax from first 3 cases (in Pa, will convert to bar)
    print("\nCalculating pressure bounds from first 3 cases...")
    all_pressures = []
    for i in range(3):
        all_pressures.extend(results[i]['loo1_pExp'])
        all_pressures.extend(results[i]['loo2_pExp'])
        all_pressures.extend(results[i]['loo3_pExp'])

    pMin_Pa = min(all_pressures)
    pMax_Pa = max(all_pressures)
    pMin_bar = pMin_Pa / 100000.0
    pMax_bar = pMax_Pa / 100000.0
    print(f"pMin = {pMin_Pa} Pa = {pMin_bar} bar")
    print(f"pMax = {pMax_Pa} Pa = {pMax_bar} bar")

    # Create plots
    print("\nCreating plots...")

    # Plot 1: 3x2 grid with all 6 cases (first 6 only)
    print("  Creating 3x2 grid plot...")
    fig1, axes = plt.subplots(3, 1, figsize=(7, 10))
    axes = axes.flatten()

    for i in range(3):
        ax = axes[i]
        data = results[i]
        time_hours = data['time'] / 3600.0  # Convert to hours

        # Filter data to show only 54-60 hours
        time_start = 54.0
        time_end = 60.0
        mask = (time_hours >= time_start) & (time_hours <= time_end)

        time_hours_filtered = time_hours[mask]
        time_hours_shifted = time_hours_filtered - time_start  # Shift to 0-6 hours

        # Convert pressures to bar (not normalized)
        p1_bar = data['loo1_pExp'] / 100000.0
        p2_bar = data['loo2_pExp'] / 100000.0
        p3_bar = data['loo3_pExp'] / 100000.0

        # Convert system pressure range to bar
        pSysMax_bar = data['pSysMax'] / 100000.0
        pSysMin_bar = data['pSysMin'] / 100000.0

        # Calculate normalized flow rates
        y1_norm = data['yPum_y1'] / m_flow_nominal
        y2_norm = data['yPum_y2'] / m_flow_nominal
        y3_norm = data['yPum_y3'] / m_flow_nominal

        # Plot pressure range polygon in background (light grey)
        ax.fill_between(time_hours_shifted, pSysMin_bar[mask], pSysMax_bar[mask],
                        color='lightgreen', alpha=0.3, zorder=0)

        # Plot pressures on primary y-axis (black, 2pt)
        ax.plot(time_hours_shifted, p1_bar[mask], 'k-', linewidth=2)
        ax.plot(time_hours_shifted, p2_bar[mask], 'k-', linewidth=2)
        ax.plot(time_hours_shifted, p3_bar[mask], 'k-', linewidth=2)

        # Create secondary y-axis for normalized flow rates
        ax2 = ax.twinx()

        # Plot normalized flow rates on secondary y-axis (faint gray, 1pt)
        ax2.plot(time_hours_shifted, y1_norm[mask], color='lightgray', linewidth=1)
        ax2.plot(time_hours_shifted, y2_norm[mask], color='lightgray', linewidth=1)
        ax2.plot(time_hours_shifted, y3_norm[mask], color='lightgray', linewidth=1)

        # Set consistent y-axis range for pressure (primary axis)
        ax.set_ylim([0, pMax_bar])

        # Set secondary y-axis range for normalized flow rates
        ax2.set_ylim([0, 1.2])

        # Add labels at t=6000s relative to window start (1.67 hours from start of 54h window)
        if 'ideal' not in data['label'].lower():
            # Original t_label was 6000s = 1.67h from simulation start
            # In 54-60h window (194400-216000s), find corresponding position
            t_label_seconds = 6000
            t_label_hours_abs = t_label_seconds / 3600.0

            # Only add labels if this time falls within our window
            if time_start <= t_label_hours_abs <= time_end:
                t_label_shifted = t_label_hours_abs - time_start
                idx_label = min(range(len(time_hours_shifted)),
                              key=lambda j: abs(time_hours_shifted[j] - t_label_shifted))
                # Position labels above the line with offset in bar units
                label_offset = (pMax_bar - pMin_bar) * 0.03
                ax.text(t_label_shifted, p1_bar[mask][idx_label] + label_offset, '1',
                       fontsize=15, ha='left', va='bottom')
                ax.text(t_label_shifted, p2_bar[mask][idx_label] + label_offset, '2',
                       fontsize=15, ha='left', va='bottom')
                ax.text(t_label_shifted, p3_bar[mask][idx_label] + label_offset, '3',
                       fontsize=15, ha='left', va='bottom')

        # Tufte-style formatting
        ax.set_title(data['label'], fontsize=15)
        ax.set_xlabel('Time [h]', fontsize=14)
        ax.set_ylabel('Expansion vessel pressure [bar]', fontsize=14)
        ax2.set_ylabel('Normalized mass flow rate [1]', fontsize=14)
        ax.tick_params(labelsize=12)
        ax2.tick_params(labelsize=12)

        # Remove top spine (right spine kept for secondary axis)
        ax.spines['top'].set_visible(False)
        ax2.spines['top'].set_visible(False)

        # Minimal grid
        ax.grid(True, alpha=0.2, linewidth=0.5, linestyle='-', color='gray')
        ax.set_axisbelow(True)

    plt.tight_layout()

    # Save plot 1
    plot1_pdf = OUT_DIR / "all_cases_grid.pdf"
    plot1_png = OUT_DIR / "all_cases_grid.png"
    fig1.savefig(plot1_pdf, dpi=300, bbox_inches='tight')
    fig1.savefig(plot1_png, dpi=300, bbox_inches='tight')
    print(f"    Saved: {plot1_pdf.name}")
    print(f"    Saved: {plot1_png.name}")
    plt.close(fig1)

    # Plot 2: Single plot with case 7 (index 3)
    print("  Creating single plot for case 7...")
    fig2, ax = plt.subplots(figsize=(10, 6))

    data = results[3]  # single plot
    time_hours = data['time'] / 3600.0  # Convert to hours

    # Filter data to show only 54-60 hours
    time_start = 54.0
    time_end = 60.0
    mask = (time_hours >= time_start) & (time_hours <= time_end)

    time_hours_filtered = time_hours[mask]
    time_hours_shifted = time_hours_filtered - time_start  # Shift to 0-6 hours

    # Convert pressures to bar (not normalized)
    p1_bar = data['loo1_pExp'] / 100000.0
    p2_bar = data['loo2_pExp'] / 100000.0
    p3_bar = data['loo3_pExp'] / 100000.0

    # Calculate normalized flow rate for yPum.y[1]
    y1_norm = data['yPum_y1'] / m_flow_nominal

    # Plot pressures on primary y-axis (black, 2pt)
    ax.plot(time_hours_shifted, p1_bar[mask], 'k-', linewidth=2)
    ax.plot(time_hours_shifted, p2_bar[mask], 'k-', linewidth=2)
    ax.plot(time_hours_shifted, p3_bar[mask], 'k-', linewidth=2)

    # Create secondary y-axis for normalized flow rate
    ax2 = ax.twinx()

    # Plot normalized flow rate on secondary y-axis (faint gray, 1pt)
    ax2.plot(time_hours_shifted, y1_norm[mask], color='lightgray', linewidth=1)

    # Set consistent y-axis range for pressure (primary axis)
    ax.set_ylim([0, pMax_bar])

    # Set secondary y-axis range for normalized flow rate
    ax2.set_ylim([0, 1.2])

    # Add labels at t=6000s relative to window start
    if 'ideal' not in data['label'].lower():
        # Original t_label was 6000s = 1.67h from simulation start
        t_label_seconds = 6000
        t_label_hours_abs = t_label_seconds / 3600.0

        # Only add labels if this time falls within our window
        if time_start <= t_label_hours_abs <= time_end:
            t_label_shifted = t_label_hours_abs - time_start
            idx_label = min(range(len(time_hours_shifted)),
                          key=lambda j: abs(time_hours_shifted[j] - t_label_shifted))
            # Position labels above the line with offset in bar units
            label_offset = (pMax_bar - pMin_bar) * 0.03
            ax.text(t_label_shifted, p1_bar[mask][idx_label] + label_offset, '1',
                   fontsize=15, ha='left', va='bottom')
            ax.text(t_label_shifted, p2_bar[mask][idx_label] + label_offset, '2',
                   fontsize=15, ha='left', va='bottom')
            ax.text(t_label_shifted, p3_bar[mask][idx_label] + label_offset, '3',
                   fontsize=15, ha='left', va='bottom')

    # Tufte-style formatting
    ax.set_title(data['label'], fontsize=15)
    ax.set_xlabel('Time [h]', fontsize=14)
    ax.set_ylabel('Expansion vessel pressure [bar]', fontsize=14)
    ax2.set_ylabel('Normalized mass flow rate [1]', fontsize=14)
    ax.tick_params(labelsize=12)
    ax2.tick_params(labelsize=12)

    # Remove top spine (right spine kept for secondary axis)
    ax.spines['top'].set_visible(False)
    ax2.spines['top'].set_visible(False)

    # Minimal grid
    ax.grid(True, alpha=0.2, linewidth=0.5, linestyle='-', color='gray')
    ax.set_axisbelow(True)

    plt.tight_layout()

    # Save plot 2
    plot2_pdf = OUT_DIR / "case7_single.pdf"
    plot2_png = OUT_DIR / "case7_single.png"
    fig2.savefig(plot2_pdf, dpi=300, bbox_inches='tight')
    fig2.savefig(plot2_png, dpi=300, bbox_inches='tight')
    print(f"    Saved: {plot2_pdf.name}")
    print(f"    Saved: {plot2_png.name}")
    plt.close(fig2)

    # Plot 3: Interloop heat transfer for the last case (case index 4)
    print("  Creating interloop heat transfer plot for last case...")
    last_data = results[4]
    time_hours = last_data['time'] / 3600.0  # Convert to hours

    # Filter data to show only 54-60 hours
    time_start = 54.0
    time_end = 60.0
    mask = (time_hours >= time_start) & (time_hours <= time_end)

    time_hours_filtered = time_hours[mask]
    time_hours_shifted = time_hours_filtered - time_start  # Shift to 0-6 hours

    fig3, axes3 = plt.subplots(2, 1, figsize=(7, 7))

    # ── Subplot 1: waste heat control signals ──────────────────────────────
    ax3a = axes3[0]
    loo1_wasHea = last_data['loo1.ySetWasHea'][mask]
    loo2_wasHea = last_data['loo2.ySetWasHea'][mask]
    ax3a.plot(time_hours_shifted, loo1_wasHea, 'k', linewidth=1.5)
    ax3a.plot(time_hours_shifted, loo2_wasHea, 'k', linewidth=1.5)

    # Labels as text above the data line at t=55.5 h absolute → 1.5 h shifted
    t_lab1 = 55.5 - time_start
    idx_lab1 = min(range(len(time_hours_shifted)),
                   key=lambda j: abs(time_hours_shifted[j] - t_lab1))
    ax3a.text(t_lab1, loo1_wasHea[idx_lab1],
              'Waste heat into loop 1 and 2', fontsize=11,
              ha='left', va='bottom')
    ax3a.text(t_lab1, loo2_wasHea[idx_lab1],
              'Waste heat out of loop 2', fontsize=11,
              ha='left', va='bottom')

    ax3a.set_ylabel('Waste heat control signal [1]', fontsize=12)
    ax3a.set_xlabel('Time [h]', fontsize=12)
    ax3a.tick_params(labelsize=11)
    ax3a.spines['top'].set_visible(False)
    ax3a.spines['right'].set_visible(False)
    ax3a.grid(True, alpha=0.2, linewidth=0.5, linestyle='-', color='gray')
    ax3a.set_axisbelow(True)

    # ── Subplot 2: loop temperatures ───────────────────────────────────────
    ax3b = axes3[1]
    # Convert K → °C
    T1_C = last_data['loo1.vol.T'][mask] - 273.15
    T2_C = last_data['loo2.vol.T'][mask] - 273.15
    T3_C = last_data['loo3.vol.T'][mask] - 273.15
    ax3b.plot(time_hours_shifted, T1_C, 'k', linewidth=1.5)
    ax3b.plot(time_hours_shifted, T2_C, 'k', linewidth=1.5)
    ax3b.plot(time_hours_shifted, T3_C, 'k', linewidth=1.5)

    # Labels as text above the data line at t=56.5 h absolute → 2.5 h shifted
    t_lab2 = 56.5 - time_start
    idx_lab2 = min(range(len(time_hours_shifted)),
                   key=lambda j: abs(time_hours_shifted[j] - t_lab2))
    ax3b.text(t_lab2, T1_C[idx_lab2], 'Loop 1', fontsize=11,
              ha='left', va='bottom')
    ax3b.text(t_lab2, T2_C[idx_lab2], 'Loop 2', fontsize=11,
              ha='left', va='bottom')
    ax3b.text(t_lab2, T3_C[idx_lab2], 'Loop 3', fontsize=11,
              ha='left', va='bottom')

    ax3b.set_ylabel(r'Loop temperatures [$^\circ \mathrm{C}$]', fontsize=12)
    ax3b.set_xlabel('Time [h]', fontsize=12)
    ax3b.tick_params(labelsize=11)
    ax3b.spines['top'].set_visible(False)
    ax3b.spines['right'].set_visible(False)
    ax3b.grid(True, alpha=0.2, linewidth=0.5, linestyle='-', color='gray')
    ax3b.set_axisbelow(True)

    plt.tight_layout()

    # Save plot 3
    plot3_pdf = OUT_DIR / "interloopHeatTransfer.pdf"
    plot3_png = OUT_DIR / "interloopHeatTransfer.png"
    fig3.savefig(plot3_pdf, dpi=300, bbox_inches='tight')
    fig3.savefig(plot3_png, dpi=300, bbox_inches='tight')
    print(f"    Saved: {plot3_pdf.name}")
    print(f"    Saved: {plot3_png.name}")
    plt.close(fig3)

    print("\n" + "="*60)
    print("POST-PROCESSING COMPLETED SUCCESSFULLY")
    print("="*60 + "\n")


def main():
    """Main function to handle command-line arguments and execute tasks."""
    parser = argparse.ArgumentParser(
        description='Simulate and post-process MeshedReservoir models using BuildingsPy.',
        formatter_class=argparse.RawDescriptionHelpFormatter
    )

    parser.add_argument('-s', '--simulate-only', action='store_true',
                        help='Simulate only (skip post-processing)')
    parser.add_argument('-p', '--postprocess-only', action='store_true',
                        help='Post-process only (skip simulation)')
    parser.add_argument('-n', '--n-processors', type=int, default=None,
                        help='Number of processors for parallel simulation (default: use all available)')
    parser.add_argument('-t', '--tool', choices=['dymola', 'openmodelica'], default='dymola',
                        help='Simulation tool to use (default: dymola)')

    args = parser.parse_args()

    # Determine number of processors
    if args.n_processors is None:
        n_processors = mp.cpu_count()
    else:
        n_processors = args.n_processors

    # Execute based on arguments
    if args.simulate_only:
        simulate(n_processors=n_processors, tool=args.tool)
    elif args.postprocess_only:
        postprocess()
    else:
        # Default: both simulate and post-process
        simulate(n_processors=n_processors, tool=args.tool)
        postprocess()


if __name__ == '__main__':
    main()