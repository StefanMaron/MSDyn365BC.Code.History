permissionset 135039 "Cues And KPIs Edit"
{
    Assignable = true;
    IncludedPermissionSets = "Cues And KPIs - Edit";
    
    // Include Test Tables
    Permissions =
        tabledata "Cues And KPIs Test 1 Cue" = RIMD,
        tabledata "Cues And KPIs Test 2 Cue" = RIMD;
}