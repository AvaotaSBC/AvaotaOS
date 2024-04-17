# AvaotaOS

## Info

```
username: avaota
password: avaota
```

## Download

From [releases](https://github.com/AvaotaSBC/AvaotaOS/releases)

ubuntu-UBUNTU_VERSION-SYS_TYPE-ARCH-BOARD.img.xz

## How to build

```
git clone --depth=1 https://github.com/AvaotaSBC/AvaotaOS && cd AvaotaOS

sudo bash build_all.sh -b <BOARD> -v <UBUNTU_VERSION> -a <ARCH> -t <SYS_TYPE>
```

BOARD: avaota-a1

UBUNTU_VERSION:
1.  Ubuntu-22.04: jammy
2.  Ubuntu-24.04: noble

ARCH:
1.  arm64: aarch64
2.  armhf: armhf

SYS_TYPE:
1.  cli
2.  xfce
3.  gnome
4.  kde
5.  lxqt

example: `bash build_all.sh -b avaota-a1 -v jammy -a aarch64 -t cli`

----
## Workflow
### Workflow Triggers

This workflow is triggered by the manual `workflow_dispatch` event.

### Permissions

This workflow requires write permissions to repository contents.

### Jobs

#### 1. prepare_release

- **Runs on:** Ubuntu 20.04
- **Steps:**
  1. **Checkout:** Fetches the repository's code.
  2. **Get time:** Retrieves the current time in the specified format.
  3. **Create empty release:** Generates an empty release with the tag name as the current time stamp from step 2. The release is created on the `ubuntu` branch and is not a draft.

#### 2. build

- **Runs on:** Ubuntu 22.04
- **Dependencies:** `prepare_release`
- **Steps:**
  1. **Checkout:** Fetches the repository's code.
  2. **Clean environment:** Cleans the environment by removing unnecessary files and packages. Installs necessary build dependencies.
  3. **Build:** Executes the `build_all.sh` script with specified parameters for building AvaotaOS for the `avaota-a1` target, using the `jammy` version, targeting `aarch64`, and building the CLI version.
  4. **Upload:** Uploads the built artifacts (`.img.xz` files) to the GitHub release if the `prepare_release` job succeeded.
  5. **Rollback release:** Rolls back the release if the `build` job fails and a release was created in the `prepare_release` job.
