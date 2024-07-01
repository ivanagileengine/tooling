#!/bin/zsh

BACKEND_DIR="/Users/ivanmonzon/Work/Projects/backend"

# Root directory where your projects are located without '/' at the end
PROJECTS_FOLDER=$BACKEND_DIR

# List of all projects
ALL_PROJECTS=($(basename $(ls -d "$PROJECTS_FOLDER"/*/)))

# List of projects folder-name to process (leave empty to process all folders as projects)
SELECTED_PROJECTS=(
    "marlin-billing"
    "marlin-calc-service"
    "marlin-common"
    "marlin-event"
    "marlin-identity"
    "marlin-load"
    "marlin-mail"
    "marlin-onboard"
    "marlin-plan-service"
    "marlin-proxy"
    "marlin-report"
    "marlin-results-service"
    "marlin-session-service"
)
PROJECTS_IGNORE=("marlin-config-server" "marlin-config" "marlin-data-migration" "marlin-jaeger")

# Map of branches
declare -A branches_mapping=(
    [marlin-billing]=release/202406.1.0
    [marlin-calc-service]=release/202406.1.0
    # [marlin-common]=rc/202406.1.0
    [marlin-event]=release/202406.1.0
    [marlin-identity]=release/202406.1.0
    [marlin-load]=release/202406.1.0
    [marlin-mail]=release/202406.1.0
    [marlin-onboard]=release/202406.1.0
    [marlin-plan-service]=release/202406.1.0
    [marlin-proxy]=release/202406.1.0
    # [marlin-report]=rc/202406.1.0
    [marlin-results-service]=release/202406.1.0
    [marlin-session-service]=release/202406.1.0
)

echo "-------------------------------------"
echo "ALL_PROJECTS_FOLDER: ($ALL_PROJECTS)"
echo "SELECTED_PROJECTS:($SELECTED_PROJECTS)"
echo "PROJECTS_IGNORE:($PROJECTS_IGNORE)"
echo "-------------------------------------"

process_project() {
    local project=$1
    local project_dir="$PROJECTS_FOLDER/$project"
    if [ -d "$project_dir" ]; then
        branch_name=${branches_mapping[$project]}
        # prev_branch_name=rc/202406.1.1
        # branch_name=develop
        echo "Processing project: ($project). Branch name: ($branch_name)"
        cd $project_dir
        # git checkout $prev_branch_name
        git branch --show-current 
        # get_latest_changes_rebase $prev_branch_name
        # print_branches_gone $branch_name
        # delete_branches_gone $branch_name
        # prune_all_other_branches $branch_name
        # create_branch_from_to $prev_branch_name $branch_name
        # git status
        # push_branch $branch_name
        # push_branch $branch_name
        # merge_develop $branch_name $project_dir
        # apply_patch_to_project $branch_name $project_dir
        # diff_and_remove_rejected_changes $project_dir
    else
        echo "Project directory not found: $project_dir"
    fi
}

add_pom_changes(){
    vim ./pom.xml
    git add pom.xml && git commit -m "Updated commons to fixed version(3.0.0)"
    git stash save -u "gilada"
    git diff origin/$branch_name
}

create_branch_from_to(){
    local prev_branch_name=$1
    local branch_name=$2
    get_latest_changes_rebase $prev_branch_name
    echo "Creating branch: $branch_name from $prev_branch_name"
    git checkout -b $branch_name $prev_branch_name
}

push_branch(){
    local branch_name=$1
    echo "Pushing branch: $branch_name"
    git push origin $branch_name
}

merge_develop(){
    local branch_name=$1
    echo "Merging develop into $branch_name"
    git checkout $branch_name
    git merge develop
    echo "------------------------"
}

apply_patch_to_project(){
    local branch_name=$1
    local project_dir=$2
    local patch_name="[deploy-alpha]_updated-commons(3_0_0-SNAPSHOT).patch"
    local patch_file="$PROJECTS_FOLDER/$patch_name"

    cd $project_dir
    echo "------------------------"
    echo "Applying patch to: $project_dir"
    echo "Patch file: $patch_file"
    git apply --intent-to-add --whitespace=fix --reject --ignore-space-change $patch_file
    echo "------------------------"
    cd -
}

prune_all_other_branches(){
    local branch_name=$1
    echo "Pruning all other branches from $branch_name"
    git pull origin $branch_name --prune
    # git branch -vv | grep -v $branch_name | grep -v develop | grep -v master | grep -v main | xargs -I {} git branch -d {}
}

SCRIPT_PATH="$(dirname $0)" # optional needed for process_rejects.sh. send it as parameter
diff_and_remove_rejected_changes(){
    local project_dir=$1
    echo "Diffing and removing rejected changes from $project_dir"
    "$SCRIPT_PATH/process_rejects.sh" $project_dir
    echo "------------------------"
}


get_latest_changes_rebase(){
    local branch=$1
    echo "Getting latest changes from $branch (rebase)"
    # git stash save -u changes-before-checkout-$branch
    git checkout $branch
    git pull origin $branch --rebase
    # git stash apply && git stash clear "\$\{HEAD\{0\}\}"
}

get_latest_branches(){
    match_word=$1
    echo "Getting latest branches from $match_word"
    git branch -av | grep $match_word
}

print_branches_gone(){
    git fetch -p
    gone_branches=$(git branch -vv | grep ': gone]' | awk '{print $1}')
    for branch in $gone_branches; do
        echo $branch
    done
}

delete_branches_gone(){
    git fetch -p
    gone_branches=$(git branch -vv | grep ': gone]' | awk '{print $1}')
    for branch in $gone_branches; do
        echo "Deleting branch: $branch"
        git branch -D $branch
    done
}


# Determine the active projects
if [ ${#SELECTED_PROJECTS[@]} -gt 0 ]; then
    # Use specified projects and exclude ignored projects
    ACTIVE_PROJECTS=("${SELECTED_PROJECTS[@]}")
    for ignore_project in "${PROJECTS_IGNORE[@]}"; do
        ACTIVE_PROJECTS=("${ACTIVE_PROJECTS[@]/$ignore_project}")
    done
else
    # Use all backend projects and exclude ignored projects
    ACTIVE_PROJECTS=("${ALL_PROJECTS[@]}")
    for ignore_project in "${PROJECTS_IGNORE[@]}"; do
        ACTIVE_PROJECTS=("${ACTIVE_PROJECTS[@]/$ignore_project}")
    done
fi

# Iterate over active projects
for project in "${ACTIVE_PROJECTS[@]}"; do
    # Extract the project name from the full path using basename
    project=$(basename "$project")
    # Call the process_project function for each project
    process_project "$project"
done
