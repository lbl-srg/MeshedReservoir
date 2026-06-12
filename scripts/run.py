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
        s.setResultFile(f"{case_name}")

        # Set configuration index (1: highPressure, 2: idealPressure, 3: lowPressure)
        conInd = case_data['parameters']['conInd']
        s.addParameters({'conInd': conInd})

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
        }

        # Get m_flow_nominal from first case
        if i == 0:
            m_flow_nominal = r.values("m_flow_nominal")[1][0]
            data['m_flow_nominal'] = m_flow_nominal

        results.append(data)
        print(f"  Read case {i}: {case_data['label']}")

    # Set m_flow_nominal
    m_flow_nominal = results[0]['m_flow_nominal']
    print(f"\nm_flow_nominal = {m_flow_nominal}")

    # Calculate pMin and pMax from first 6 cases
    print("\nCalculating pressure bounds from first 6 cases...")
    all_pressures = []
    for i in range(3):
        all_pressures.extend(results[i]['loo1_pExp'])
        all_pressures.extend(results[i]['loo2_pExp'])
        all_pressures.extend(results[i]['loo3_pExp'])

    pMin = min(all_pressures)
    pMax = max(all_pressures)
    print(f"pMin = {pMin}")
    print(f"pMax = {pMax}")

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

        # Calculate normalized pressures
        p1_norm = (data['loo1_pExp']-pMin) / (pMax - pMin)
        p2_norm = (data['loo2_pExp']-pMin) / (pMax - pMin)
        p3_norm = (data['loo3_pExp']-pMin) / (pMax - pMin)

        # Calculate normalized flow rates
        y1_norm = data['yPum_y1'] / m_flow_nominal
        y2_norm = data['yPum_y2'] / m_flow_nominal
        y3_norm = data['yPum_y3'] / m_flow_nominal

        # Plot normalized flow rates (faint gray, 1pt)
        ax.plot(time_hours_shifted, y1_norm[mask], color='lightgray', linewidth=1)
        ax.plot(time_hours_shifted, y2_norm[mask], color='lightgray', linewidth=1)
        ax.plot(time_hours_shifted, y3_norm[mask], color='lightgray', linewidth=1)

        # Plot normalized pressures (black, 2pt)
        ax.plot(time_hours_shifted, p1_norm[mask], 'k-', linewidth=2)
        ax.plot(time_hours_shifted, p2_norm[mask], 'k-', linewidth=2)
        ax.plot(time_hours_shifted, p3_norm[mask], 'k-', linewidth=2)

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
                # Position labels above the line with ~1em spacing (0.05 in normalized units)
                label_offset = 0.05
                ax.text(t_label_shifted, p1_norm[mask][idx_label] + label_offset, '1',
                       fontsize=15, ha='left', va='bottom')
                ax.text(t_label_shifted, p2_norm[mask][idx_label] + label_offset, '2',
                       fontsize=15, ha='left', va='bottom')
                ax.text(t_label_shifted, p3_norm[mask][idx_label] + label_offset, '3',
                       fontsize=15, ha='left', va='bottom')

        # Tufte-style formatting
        ax.set_title(data['label'], fontsize=15)
        ax.set_xlabel('Time [h]', fontsize=14)
        ax.set_ylabel('Normalized pressure and\nmass flow rate [1]', fontsize=14)
        ax.tick_params(labelsize=12)

        # Remove top and right spines
        ax.spines['top'].set_visible(False)
        ax.spines['right'].set_visible(False)

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

    # Plot 2: Single plot with case 7 (index 6)
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

    # Calculate normalized pressures
    p1_norm = (pMax - data['loo1_pExp']) / (pMax - pMin)
    p2_norm = (pMax - data['loo2_pExp']) / (pMax - pMin)
    p3_norm = (pMax - data['loo3_pExp']) / (pMax - pMin)

    # Calculate normalized flow rate for yPum.y[1]
    y1_norm = data['yPum_y1'] / m_flow_nominal

    # Plot normalized flow rate (faint gray, 1pt)
    ax.plot(time_hours_shifted, y1_norm[mask], color='lightgray', linewidth=1)

    # Plot normalized pressures (black, 2pt)
    ax.plot(time_hours_shifted, p1_norm[mask], 'k-', linewidth=2)
    ax.plot(time_hours_shifted, p2_norm[mask], 'k-', linewidth=2)
    ax.plot(time_hours_shifted, p3_norm[mask], 'k-', linewidth=2)

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
            # Position labels above the line with ~1em spacing (0.05 in normalized units)
            label_offset = 0.05
            ax.text(t_label_shifted, p1_norm[mask][idx_label] + label_offset, '1',
                   fontsize=15, ha='left', va='bottom')
            ax.text(t_label_shifted, p2_norm[mask][idx_label] + label_offset, '2',
                   fontsize=15, ha='left', va='bottom')
            ax.text(t_label_shifted, p3_norm[mask][idx_label] + label_offset, '3',
                   fontsize=15, ha='left', va='bottom')

    # Tufte-style formatting
    ax.set_title(data['label'], fontsize=15)
    ax.set_xlabel('Time [h]', fontsize=14)
    ax.set_ylabel('Normalized pressure and\nmass flow rate [1]', fontsize=14)
    ax.tick_params(labelsize=12)

    # Remove top and right spines
    ax.spines['top'].set_visible(False)
    ax.spines['right'].set_visible(False)

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