codeunit 1174 "User Task Management"
{
    // // Code unit to manage user tasks / user tasks groups.
    // // Due date filter options :-
    // // NONE :- All pending tasks assigned to logged in user or their groups.
    // // TODAY :- All pending tasks assigned to logged in user or their groups due today.
    // // THIS_WEEK :- All pending tasks assigned to logged in user or their groups due this week.


    trigger OnRun()
    begin
    end;

    var
        UserTaskGroupMember: Record "User Task Group Member";
        DueDateFilterOptions: Option "NONE",TODAY,THIS_WEEK;

    procedure GetMyPendingUserTasksCount(): Integer
    begin
        // Gets total count of user tasks assgined to logged in user.
        // This includes tasks assigned to the user and their groups.
        exit(CalculateUserTasksCount(DueDateFilterOptions::NONE));
    end;

    procedure GetMyPendingUserTasksCountDueToday(): Integer
    begin
        // Gets total count of user tasks assgined to logged in user.
        // This includes tasks assigned to the user and their groups due today.
        exit(CalculateUserTasksCount(DueDateFilterOptions::TODAY));
    end;

    procedure GetMyPendingUserTasksCountDueThisWeek(): Integer
    begin
        // Gets total count of user tasks assgined to logged in user.
        // This includes tasks assigned to the user and their groups due this week.
        exit(CalculateUserTasksCount(DueDateFilterOptions::THIS_WEEK));
    end;

    procedure SetFiltersToShowMyUserTasks(var UserTask: Record "User Task"; DueDateFilterOption: Integer)
    var
        MyTasksUserGroups: Text;
    begin
        MyTasksUserGroups := GetMyTasksUserGroupsAsFilterText;

        if MyTasksUserGroups <> '' then begin
            UserTask.FilterGroup(-1);
            UserTask.SetFilter("User Task Group Assigned To", MyTasksUserGroups);
            UserTask.SetFilter("Assigned To", UserSecurityId);
            UserTask.FilterGroup(25);
            UserTask.SetFilter("Percent Complete", '<>100');
        end else begin
            UserTask.SetFilter("Assigned To", UserSecurityId);
            UserTask.SetFilter("Percent Complete", '<>100');
        end;

        case DueDateFilterOption of
            DueDateFilterOptions::NONE:
                UserTask.SetRange("Due DateTime");
            DueDateFilterOptions::THIS_WEEK:
                UserTask.SetFilter("Due DateTime", '<>%1 & <=%2', 0DT, CreateDateTime(CalcDate('<CW>'), 0T));
            DueDateFilterOptions::TODAY:
                UserTask.SetFilter("Due DateTime", '<>%1 & <=%2', 0DT, CurrentDateTime);
        end;
    end;

    [EventSubscriber(ObjectType::Table, 1175, 'OnAfterDeleteEvent', '', false, false)]
    local procedure OnAfterDeleteUserTaskGroup(var Rec: Record "User Task Group"; RunTrigger: Boolean)
    var
        UserTask: Record "User Task";
    begin
        UserTask.SetRange("User Task Group Assigned To", Rec.Code);
        // empty out 'user task group assigned to' for the tasks that were assigned to the user task group that is being deleted
        UserTask.ModifyAll("User Task Group Assigned To", '');
    end;

    local procedure CalculateUserTasksCount(DueDateFilterOption: Integer): Integer
    var
        UserTask: Record "User Task";
    begin
        UserTask.Reset();
        SetFiltersToShowMyUserTasks(UserTask, DueDateFilterOption);
        exit(UserTask.Count);
    end;

    local procedure GetMyTasksUserGroupsAsFilterText(): Text
    var
        FilterTxt: Text;
    begin
        // Returns a text contaning all the groups that logged in user belong to which can be used for setting filter
        // Example - If user belongs to 'A' and 'C' user tasks groups this function will return 'A|C' as filter text.
        UserTaskGroupMember.Reset();
        UserTaskGroupMember.SetRange("User Security ID", UserSecurityId);
        if UserTaskGroupMember.FindSet then begin
            repeat
                FilterTxt := FilterTxt + UserTaskGroupMember."User Task Group Code" + '|';
            until UserTaskGroupMember.Next = 0;
        end;

        // delete last char (|) to create a filter string
        if StrLen(FilterTxt) > 1 then
            FilterTxt := DelStr(FilterTxt, StrLen(FilterTxt), 1);
        exit(FilterTxt);
    end;
}

