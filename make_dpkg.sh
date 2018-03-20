#!/bin/bash

# set -x
set -e

SCRIPT_DIR=$(dirname $(readlink -f $0))
TMP_DIR=$(mktemp -d)
WORK_DIR=${TMP_DIR}/work


mkdir -p ${WORK_DIR}/opt/aiy/projects-python
git ls-files | rsync -avz --exclude="debian/*" --files-from - . ${WORK_DIR}/opt/aiy/projects-python
cp -r debian ${WORK_DIR}

# Copy aiyprojects and set remote to github.
AIY_PYTHON_DIR=${WORK_DIR}/opt/aiy/projects-python
rm -f ${AIY_PYTHON_DIR}/.git
if [ -d ${AIY_PYTHON_DIR}/.git ]; then
    rsync -rL --exclude=.git/shallow ${SCRIPT_DIR}/.git ${AIY_PYTHON_DIR}
else
    cp -r ${SCRIPT_DIR}/../.git/modules/aiy-projects-python ${AIY_PYTHON_DIR}/.git
fi
ls -la ${AIY_PYTHON_DIR}/.git/
sed -i '/\tworktree =/d' ${AIY_PYTHON_DIR}/.git/config
git -C ${AIY_PYTHON_DIR} checkout aiyprojects
for BRANCH in $(git -C ${AIY_PYTHON_DIR} branch | sed 's/\*//'); do
    if [[ "$BRANCH" != "aiyprojects" ]]; then
        git -C ${AIY_PYTHON_DIR} branch -D ${BRANCH}
    fi
done
git -C ${AIY_PYTHON_DIR} remote remove origin | true
git -C ${AIY_PYTHON_DIR} remote add origin \
    https://github.com/google/aiyprojects-raspbian

pushd ${WORK_DIR}
dpkg-buildpackage -b -rfakeroot -us -uc
popd

cp ${TMP_DIR}/aiy-projects-python_*_all.deb ${SCRIPT_DIR}
rm -rf ${WORK_DIR}
