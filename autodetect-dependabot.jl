module AutodetectDependabot

function _get_possible_branch_names()
    possible_branch_names = [
        get(ENV, "GITHUB_BASE_REF", ""),
        get(ENV, "GITHUB_HEAD_REF", ""),
        get(ENV, "GITHUB_REF", ""),
    ]
    return possible_branch_names
end

function _chop_refs_head(branch_name::AbstractString)
    if startswith(branch_name, "refs/heads/")
        return replace(branch_name, r"^(refs\/heads\/)" => "")
    else
        return branch_name
    end
end

function _is_dependabot_branch(branch_name::AbstractString)
    return startswith(branch_name, "dependabot/julia") || startswith(branch_name, "compathelper/")
end

function is_dependabot_job()
    possible_branch_names = _get_possible_branch_names()
    return any(_is_dependabot_branch.(_chop_refs_head.(possible_branch_names)))
end

end # module
