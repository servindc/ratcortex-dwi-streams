# ratCortex-dMRIstreams

Scripts to process dMRI volumes and create cortical streamlines in rat data.

## Setup

1. Install the [MINC](https://en.wikibooks.org/wiki/MINC) tools required for the code:
    ```bash
    sudo apt install minc-tools
    ```

2. Create a conda environment:
    ```bash
    conda env create --file environment.yml
    ```

3. Activate the environment:
    ```bash
    conda activate cx-streams-env
    ```

:information_source: [**Info & details**](https://hackmd.io/@servindc/ratCortex-dMRI)