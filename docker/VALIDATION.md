# Local container validation

Validated on October 24, 2026. This records an operational smoke test and is not
scientific accuracy validation or published-result reproduction.

## Environment and scope

- Source baseline: `7dc5563300e7143582d85636bdd413d4c7688e9a`.
- Branch: `feature/containerized-placer`, independent of the editable-install branch.
- Docker Desktop 4.47.0 / Engine 28.4.0, Linux x86_64 backend on Windows/WSL2.
- NVIDIA GeForce RTX 3080, 10 GiB VRAM, driver 621.01.
- Python 3.10.16 / PyTorch 2.3.1 / CUDA 12.1 / DGL 2.4.0+cu121.
- SE(3) Transformer 1.2.0 at the Git revision pinned in the Dockerfile.

## Results

| Check | Result |
| --- | --- |
| Fresh dependency installation and image build | PASS |
| Default CLI help, without GPU access or network | PASS |
| PLACER import and bundled resource presence, offline | PASS |
| CUDA availability and an actual CUDA tensor operation | PASS |
| One-sample inference using bundled `dnHEM1_apo.pdb`, target A-149 | PASS |
| Inference with `--network none`, no source/environment mounts | PASS |
| Output directory bind mount, arbitrary UID/GID 1000:1000, `HOME=/tmp` | PASS |
| Output ownership matches selected UID | PASS |
| One CSV score row, expected columns and finite numeric scores | PASS |
| One PDB model, finite coordinates, 598 ATOM/HETATM records | PASS |
| Host Conda package versions and pip branch unchanged | PASS |

The completed local image occupied 8.35 GB (approximately 7.78 GiB) before
registry compression. The explicit Conda archives total approximately 2.98 GiB.
Docker build caches and intermediate stages consume additional local space.

The model reported 3.11 seconds for the sample, 3.88 seconds for the prediction
loop, and approximately 3.13 GB GPU memory. These are observations from this
sample, not performance or resource guarantees. Timings exclude image download,
container startup, imports, and checkpoint initialization.

Generated score columns were `label`, `model_idx`, `fape`, `lddt`, `rmsd`,
`kabsch`, `prmsd`, `plddt`, and `plddt_pde`. Numerical results and crop atom counts
can vary between stochastic runs. This apo side-chain example does not establish
ligand-docking accuracy.

Build, CLI, GPU, and inference logs and a machine-readable output summary were
saved outside the checkout. No registry image was published. Native Linux hosts,
other NVIDIA GPUs, CPU inference, Apple Silicon, and new Python versions were
not validated.
