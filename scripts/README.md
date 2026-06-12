# MeshedReservoir Simulation Scripts

This directory contains Python scripts for simulating and post-processing MeshedReservoir models using BuildingsPy 5.2.0.

## Files

- `run.py` - Main Python script for simulation and post-processing
- `run.sh` - Shell wrapper for convenient execution
- `simulation_cases.yaml` - YAML configuration file defining simulation cases
- `README.md` - This file

## Requirements

- Python 3.x
- BuildingsPy 5.2.0
- PyYAML
- Matplotlib
- NumPy
- Dymola or OpenModelica

Install Python dependencies:
```bash
pip install buildingspy==5.2.0 pyyaml matplotlib numpy
```

## Usage

### Basic Usage

Run both simulation and post-processing:
```bash
./run.py
# or
./run.sh
```

### Command-line Options

- `-h, --help` - Show help message
- `-s, --simulate-only` - Run simulation only (skip post-processing)
- `-p, --postprocess-only` - Run post-processing only (skip simulation)
- `-n N, --n-processors N` - Number of processors for parallel simulation (default: all available)
- `-t {dymola,openmodelica}, --tool {dymola,openmodelica}` - Simulation tool to use (default: dymola)

### Examples

Simulate only with 4 processors using Dymola:
```bash
./run.py -s -n 4 -t dymola
```

Post-process only:
```bash
./run.py -p
```

Run sequentially (one case at a time) using OpenModelica:
```bash
./run.py -n 1 -t openmodelica
```

## Simulation Cases

The `simulation_cases.yaml` file defines 7 simulation cases:

### Cases 1-6: Variable configurations with two pump schedules

- **Cases 1-3**: Using `pumSchRam` (ramp schedule)
  - Case 1: High configuration (all features enabled)
  - Case 2: Ideal configuration (no pump stream)
  - Case 3: Low configuration (no pump stream, no upstream expansion vessel)

- **Cases 4-6**: Using `pumSchDip` (trapezoid schedule)
  - Case 4: High configuration (all features enabled)
  - Case 5: Ideal configuration (no pump stream)
  - Case 6: Low configuration (no pump stream, no upstream expansion vessel)

### Case 7: Constant pump with ideal configuration

- Uses `pumSchOn` (constant on)
- Ideal configuration with all features enabled

## Configuration Parameters

All cases share these simulation settings:
- Model: `MeshedReservoir.Examples.ThreeLoops`
- Start time: 0 s
- Stop time: 10800 s
- Solver: CVode
- Tolerance: 1E-6

Each case varies the following parameters for loops `loo1`, `loo2`, and `loo3`:
- `have_pumpUpstream` - Enable/disable pump stream
- `have_expansionVesselUpstream` - Enable/disable upstream expansion vessel
- `addHeat` - Enable/disable heat addition (always true in current config)

## Output

### Simulation Output

Simulation results are stored in `../out/simulations/`:
- `.mat` files containing simulation results
- Filenames follow pattern: `ThreeLoops_{config}_{pump_type}_case{index}.mat`

### Post-processing Output

Post-processing generates plots in `../out/`:

1. **all_cases_grid.pdf/png** - 3x2 grid showing all 6 variable configuration cases
   - Each subplot shows normalized pressures (black, 2pt lines) and flow rates (gray, 1pt lines)
   - Curves labeled with 1, 2, 3 for loops loo1, loo2, loo3

2. **case7_single.pdf/png** - Single plot for case 7 (constant pump)
   - Shows normalized pressures (black, 2pt lines) and flow rate for yPum.y[1] (gray, 1pt)
   - Curves labeled with 1, 2, 3 for loops

## Implementation Details

### mat_name Function

Generates standardized filenames for simulation output based on:
- Case index
- Pump schedule (pumSchRam, pumSchDip, pumSchOn)
- Configuration parameters

### Simulation Function

1. Reads YAML configuration
2. Deletes and recreates output directory
3. Sets up simulation cases with BuildingsPy Simulator
4. Runs simulations (sequentially or in parallel)
5. Verifies all simulations completed successfully
6. Cleans up auxiliary files (dsin.txt, dsmodel.txt, dymosim, dsfinal.txt)

### Post-processing Function

1. Deletes existing plots in output directory
2. Reads all simulation results
3. Verifies simulation completion
4. Calculates pressure bounds (pMin, pMax) from first 6 cases
5. Reads m_flow_nominal from model
6. Creates normalized plots:
   - Normalized pressure: (pMax - p) / (pMax - pMin)
   - Normalized flow: y / m_flow_nominal
7. Saves plots as PDF and PNG

## Error Handling

The script includes robust error handling:
- Verifies all simulations complete to stopTime (within 1E-6 tolerance)
- Reports specific errors for failed simulations
- Exits with error code 1 on failure
- Checks for missing output files

## Troubleshooting

If simulations fail:
1. Check that Dymola or OpenModelica is properly installed
2. Verify BuildingsPy is correctly configured
3. Check that the MeshedReservoir library is in the MODELICAPATH
4. Review error messages for specific simulation failures

If post-processing fails:
1. Ensure all .mat files exist in `../out/simulations/`
2. Verify simulations completed successfully
3. Check that matplotlib and numpy are installed