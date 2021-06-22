page 5146 "Assign Activity"
{
    Caption = 'Assign Activity';
    DataCaptionExpression = Caption;
    DeleteAllowed = false;
    InsertAllowed = false;
    LinksAllowed = false;
    PageType = Card;
    SourceTable = "To-do";

    layout
    {
        area(content)
        {
            group("Activity Setup")
            {
                Caption = 'Activity Setup';
                field("Activity Code"; "Activity Code")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Activity Code';
                    TableRelation = Activity.Code;
                    ToolTip = 'Specifies a code for the task activity.';

                    trigger OnValidate()
                    begin
                        if not Activity.IncludesMeeting("Activity Code") then begin
                            TeamMeetingOrganizerEditable := false;
                            "Team Meeting Organizer" := ''
                        end else
                            if "Team Code" <> '' then begin
                                TeamMeetingOrganizerEditable := true;
                                "Team Meeting Organizer" := ''
                            end;
                    end;
                }
                field(Date; Date)
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Activity Start Date';
                    ToolTip = 'Specifies the date when the task should be started. There are certain rules for how dates should be entered found in How to: Enter Dates and Times.';
                }
                field("Wizard Contact Name"; "Wizard Contact Name")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Contact No.';
                    Editable = WizardContactNameEditable;
                    Lookup = false;
                    TableRelation = Contact;
                    ToolTip = 'Specifies a contact name from the wizard.';

                    trigger OnAssistEdit()
                    var
                        Cont: Record Contact;
                    begin
                        if ("Wizard Contact Name" = '') and not SegHeader.Get(GetFilter("Segment No.")) then begin
                            if Cont.Get("Contact No.") then;
                            if PAGE.RunModal(0, Cont) = ACTION::LookupOK then begin
                                Validate("Contact No.", Cont."No.");
                                CurrPage.SetSelectionFilter(Rec);
                                "Wizard Contact Name" := Cont.Name;
                            end;
                        end;
                    end;
                }
                field("Salesperson Code"; "Salesperson Code")
                {
                    ApplicationArea = Suite, RelationshipMgmt;
                    Caption = 'Salesperson Code';
                    Editable = SalespersonCodeEditable;
                    ToolTip = 'Specifies the code of the salesperson assigned to the task.';

                    trigger OnValidate()
                    begin
                        if SalesPurchPerson.Get("Salesperson Code") then begin
                            TeamMeetingOrganizerEditable := false;
                            "Team Meeting Organizer" := '';
                            "Team Code" := ''
                        end else
                            if Activity.IncludesMeeting("Activity Code") or
                               ("Activity Code" = '') and
                               ("Team Code" <> '')
                            then
                                TeamMeetingOrganizerEditable := true
                    end;
                }
                field("Team Code"; "Team Code")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Team Code';
                    Editable = TeamCodeEditable;
                    ToolTip = 'Specifies the code of the team to which the task is assigned.';

                    trigger OnValidate()
                    begin
                        if Team.Get("Team Code") then begin
                            if Activity.IncludesMeeting("Activity Code") then
                                TeamMeetingOrganizerEditable := true;
                            "Salesperson Code" := '';
                        end;
                        if "Team Code" = '' then begin
                            TeamMeetingOrganizerEditable := false;
                            "Team Meeting Organizer" := ''
                        end;
                    end;
                }
                field("Team Meeting Organizer"; "Team Meeting Organizer")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Meeting Organizer';
                    Editable = TeamMeetingOrganizerEditable;
                    ToolTip = 'Specifies who on the team is the organizer of the task. You can modify the value in this field with the appropriate name when the to-do is for a team.';

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        Salesperson: Record "Salesperson/Purchaser";
                        SalesPurchPerson: Page "Salespersons/Purchasers";
                    begin
                        SalesPurchPerson.LookupMode := true;
                        if SalesPurchPerson.RunModal = ACTION::LookupOK then begin
                            SalesPurchPerson.GetRecord(Salesperson);
                            if TeamMeetingOrganizerEditable then
                                "Team Meeting Organizer" := Salesperson.Code
                        end;
                    end;

                    trigger OnValidate()
                    var
                        SalesPurchPerson: Record "Salesperson/Purchaser";
                    begin
                        SalesPurchPerson.Get("Team Meeting Organizer");
                    end;
                }
                field("Wizard Campaign Description"; "Wizard Campaign Description")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Campaign';
                    Importance = Additional;
                    Lookup = false;
                    TableRelation = Campaign;
                    ToolTip = 'Specifies a description of the campaign that is related to the task. The description is copied from the campaign card.';

                    trigger OnAssistEdit()
                    var
                        Campaign: Record Campaign;
                    begin
                        if not Campaign.Get(GetFilter("Campaign No.")) then begin
                            if Campaign.Get("Campaign No.") then;
                            if PAGE.RunModal(0, Campaign) = ACTION::LookupOK then begin
                                Validate("Campaign No.", Campaign."No.");
                                "Wizard Campaign Description" := Campaign.Description;
                            end;
                        end;
                    end;
                }
                field("Segment Description"; "Segment Description")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Create Tasks for Segment';
                    Editable = false;
                    Importance = Additional;
                    Lookup = false;
                    TableRelation = "Segment Header";
                    ToolTip = 'Specifies a description of the segment related to the task. The description is copied from the segment card.';

                    trigger OnAssistEdit()
                    var
                        Segment: Record "Segment Header";
                    begin
                        if Segment.Get("Segment No.") then;
                        if PAGE.RunModal(0, Segment) = ACTION::LookupOK then begin
                            Validate("Segment No.", Segment."No.");
                            "Segment Description" := Segment.Description;
                        end;
                    end;
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(Finish)
            {
                ApplicationArea = RelationshipMgmt;
                Caption = '&Finish';
                Image = Approve;
                InFooterBar = true;
                Promoted = true;
                ToolTip = 'Finish assigning the activity.';
                Visible = IsOnMobile;

                trigger OnAction()
                begin
                    CheckAssignActivityStatus;
                    FinishAssignActivity;
                    CurrPage.Close;
                end;
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        WizardContactNameOnFormat(Format("Wizard Contact Name"));
    end;

    trigger OnInit()
    begin
        TeamCodeEditable := true;
        SalespersonCodeEditable := true;
        WizardContactNameEditable := true;
        TeamMeetingOrganizerEditable := true;
    end;

    trigger OnOpenPage()
    begin
        WizardContactNameEditable := false;
        IsOnMobile := ClientTypeManagement.GetCurrentClientType = CLIENTTYPE::Phone;

        if SalesPurchPerson.Get(GetFilter("Salesperson Code")) or
           Team.Get(GetFilter("Team Code"))
        then begin
            SalespersonCodeEditable := false;
            TeamCodeEditable := false;
        end;

        if SalesPurchPerson.Get(GetFilter("Salesperson Code")) or
           ("Salesperson Code" <> '') or
           ("Activity Code" = '')
        then
            TeamMeetingOrganizerEditable := false;

        if Campaign.Get(GetFilter("Campaign No.")) then
            "Campaign Description" := Campaign.Description;

        if SegHeader.Get(GetFilter("Segment No.")) then
            "Segment Description" := SegHeader.Description;
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        if CloseAction in [ACTION::OK, ACTION::LookupOK] then begin
            CheckAssignActivityStatus;
            FinishAssignActivity;
        end;
    end;

    var
        Text000: Label 'untitled';
        Cont: Record Contact;
        SalesPurchPerson: Record "Salesperson/Purchaser";
        Team: Record Team;
        Campaign: Record Campaign;
        SegHeader: Record "Segment Header";
        Activity: Record Activity;
        Text005: Label '(Multiple)';
        ClientTypeManagement: Codeunit "Client Type Management";
        [InDataSet]
        TeamMeetingOrganizerEditable: Boolean;
        [InDataSet]
        WizardContactNameEditable: Boolean;
        [InDataSet]
        SalespersonCodeEditable: Boolean;
        [InDataSet]
        TeamCodeEditable: Boolean;
        IsOnMobile: Boolean;

    procedure Caption(): Text
    var
        CaptionStr: Text;
    begin
        if Cont.Get(GetFilter("Contact Company No.")) then
            CaptionStr := CopyStr(Cont."No." + ' ' + Cont.Name, 1, MaxStrLen(CaptionStr));
        if Cont.Get(GetFilter("Contact No.")) then
            CaptionStr := CopyStr(CaptionStr + ' ' + Cont."No." + ' ' + Cont.Name, 1, MaxStrLen(CaptionStr));
        if SalesPurchPerson.Get(GetFilter("Salesperson Code")) then
            CaptionStr := CopyStr(CaptionStr + ' ' + SalesPurchPerson.Code + ' ' + SalesPurchPerson.Name, 1, MaxStrLen(CaptionStr));
        if Team.Get(GetFilter("Team Code")) then
            CaptionStr := CopyStr(CaptionStr + ' ' + Team.Code + ' ' + Team.Name, 1, MaxStrLen(CaptionStr));
        if Campaign.Get(GetFilter("Campaign No.")) then
            CaptionStr := CopyStr(CaptionStr + ' ' + Campaign."No." + ' ' + Campaign.Description, 1, MaxStrLen(CaptionStr));
        if SegHeader.Get(GetFilter("Segment No.")) then
            CaptionStr := CopyStr(CaptionStr + ' ' + SegHeader."No." + ' ' + SegHeader.Description, 1, MaxStrLen(CaptionStr));
        if CaptionStr = '' then
            CaptionStr := Text000;

        exit(CaptionStr);
    end;

    local procedure WizardContactNameOnFormat(Text: Text[1024])
    begin
        if SegHeader.Get(GetFilter("Segment No.")) then
            Text := Text005;
    end;
}

