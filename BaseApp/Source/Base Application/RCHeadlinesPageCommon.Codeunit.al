codeunit 1440 "RC Headlines Page Common"
{

    var
        HeadlineManagement: Codeunit Headlines;
        HeadlineRC: Codeunit "RC Headlines Executor";
        DefaultFieldsVisible: Boolean;
        DocumentationTxt: Label 'Want to learn more about %1?', Comment = '%1 is the Business Central short product name.';
        GreetingText: Text[250];
        DocumentationText: Text[250];
        UserGreetingVisible: Boolean;

    procedure HeadlineOnOpenPage(RoleCenterPageID: Integer)
    var
        RoleCenterHeadlines: Record "RC Headlines User Data";
    begin
        if RoleCenterHeadlines.WritePermission() then begin
            if not RoleCenterHeadlines.Get(UserSecurityId(), RoleCenterPageID) then begin
                RoleCenterHeadlines.Init();
                RoleCenterHeadlines."Role Center Page ID" := RoleCenterPageID;
                RoleCenterHeadlines."User ID" := UserSecurityId();
                RoleCenterHeadlines.Insert();
            end;
            RoleCenterHeadlines."User workdate" := WorkDate;
            RoleCenterHeadlines.Modify();
            HeadlineRC.ScheduleTask(RoleCenterPageID);
        end;

        GreetingText := HeadlineManagement.GetUserGreetingText();
        DocumentationText := StrSubstNo(DocumentationTxt, PRODUCTNAME.Short);

        ComputeDefaultFieldsVisibility(RoleCenterPageID);

        Commit(); // not to mess up the other page parts that may do IF CODEUNIT.RUN()
    end;

    procedure ComputeDefaultFieldsVisibility(RoleCenterPageID: Integer)
    var
        ExtensionHeadlinesVisible: Boolean;
    begin
        OnIsAnyExtensionHeadlineVisible(ExtensionHeadlinesVisible, RoleCenterPageID);
        DefaultFieldsVisible := not ExtensionHeadlinesVisible;
        UserGreetingVisible := HeadlineManagement.ShouldUserGreetingBeVisible;
    end;

    procedure DocumentationUrlTxt(): Text
    begin
        exit('https://go.microsoft.com/fwlink/?linkid=867580');
    end;

    procedure IsUserGreetingVisible(): Boolean
    begin
        exit(UserGreetingVisible);
    end;

    procedure GetGreetingText(): Text
    begin
        exit(GreetingText);
    end;

    procedure AreDefaultFieldsVisible(): Boolean
    begin
        exit(DefaultFieldsVisible);
    end;

    procedure GetDocumentationText(): Text
    begin
        exit(DocumentationText);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnIsAnyExtensionHeadlineVisible(var ExtensionHeadlinesVisible: Boolean; RoleCenterPageID: Integer)
    begin
    end;
}

