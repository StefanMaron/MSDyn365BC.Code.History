page 5097 "Create Task"
{
    Caption = 'Create Task';
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
            group(General)
            {
                Caption = 'General';
                field(TypeSaaS; Type)
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Type';
                    OptionCaption = ' ,,Phone Call';
                    ToolTip = 'Specifies the type of the Task.';
                    Visible = IsSoftwareAsAService;

                    trigger OnValidate()
                    begin
                        ValidateTypeField;
                    end;
                }
                field(TypeOnPrem; Type)
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Type';
                    OptionCaption = ' ,Meeting,Phone Call';
                    ToolTip = 'Specifies the type of the Task.';
                    Visible = NOT IsSoftwareAsAService;

                    trigger OnValidate()
                    begin
                        ValidateTypeField;
                    end;
                }
                field(Description; Description)
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the description of the Task.';
                }
                field(AllDayEvent; "All Day Event")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'All Day Event';
                    Enabled = AllDayEventEnable;
                    ToolTip = 'Specifies that the Task of the Meeting type is an all-day event, which is an activity that lasts 24 hours or longer.';

                    trigger OnValidate()
                    begin
                        AllDayEventOnAfterValidate;
                    end;
                }
                field(Date; Date)
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Start Date';
                    ToolTip = 'Specifies the date when the Task should be started. There are certain rules for how dates should be entered found in How to: Enter Dates and Times.';
                }
                field("Start Time"; "Start Time")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Start Time';
                    Enabled = StartTimeEnable;
                    ToolTip = 'Specifies the time when the Task of the Meeting type should be started.';
                }
                field(Duration; Duration)
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Duration';
                    Enabled = DurationEnable;
                    ToolTip = 'Specifies the duration of the Task of the Meeting type.';
                }
                field("Ending Date"; "Ending Date")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Ending Date';
                    ToolTip = 'Specifies the date of when the Task should end. There are certain rules for how dates should be entered. For more information, see How to: Enter Dates and Times.';
                }
                field("Ending Time"; "Ending Time")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Ending Time';
                    Enabled = EndingTimeEnable;
                    ToolTip = 'Specifies the time of when the Task of the Meeting type should end.';
                }
                field(TeamTask; "Team To-do")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Team Task';
                    Editable = TeamTaskEditable;
                    ToolTip = 'Specifies if the Task is meant to be done team-wide. Select the check box to specify that the Task applies to the entire Team.';

                    trigger OnValidate()
                    begin
                        if not "Team To-do" then begin
                            "Team Code" := '';
                            SalespersonCodeEnable := false;
                            if Type = Type::Meeting then begin
                                ClearDefaultAttendeeInfo;
                                AssignDefaultAttendeeInfo;
                            end;
                        end;
                    end;
                }
                field("Wizard Contact Name"; "Wizard Contact Name")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Contact';
                    Editable = WizardContactNameEditable;
                    Enabled = WizardContactNameEnable;
                    Lookup = false;
                    TableRelation = Contact;
                    ToolTip = 'Specifies a Contact name from the wizard.';

                    trigger OnAssistEdit()
                    var
                        Cont: Record Contact;
                    begin
                        if (GetFilter("Contact No.") = '') and (GetFilter("Contact Company No.") = '') and ("Segment Description" = '') then begin
                            if Cont.Get("Contact No.") then;
                            if PAGE.RunModal(0, Cont) = ACTION::LookupOK then begin
                                Validate("Contact No.", Cont."No.");
                                "Wizard Contact Name" := Cont.Name;
                            end;
                        end;
                    end;
                }
                field("Salesperson Code"; "Salesperson Code")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Salesperson';
                    Editable = SalespersonCodeEditable;
                    Enabled = SalespersonCodeEnable;
                    ToolTip = 'Specifies the code of the Salesperson assigned to the Task.';
                }
                field("Team Code"; "Team Code")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Team';
                    Editable = "Team To-do";
                    Enabled = "Team To-do" OR NOT IsMeeting;
                    ToolTip = 'Specifies the code of the Team to which the Task is assigned.';

                    trigger OnValidate()
                    begin
                        if (xRec."Team Code" <> "Team Code") and
                           ("Team Code" <> '') and
                           (Type = Type::Meeting)
                        then begin
                            ClearDefaultAttendeeInfo;
                            AssignDefaultAttendeeInfo
                        end
                    end;
                }
                field("Wizard Campaign Description"; "Wizard Campaign Description")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Campaign';
                    Editable = WizardCampaignDescriptionEdita;
                    Importance = Additional;
                    Lookup = false;
                    TableRelation = Campaign;
                    ToolTip = 'Specifies a description of the campaign that is related to the task. The description is copied from the campaign card.';

                    trigger OnAssistEdit()
                    var
                        Campaign: Record Campaign;
                    begin
                        if GetFilter("Campaign No.") = '' then begin
                            if Campaign.Get("Campaign No.") then;
                            if PAGE.RunModal(0, Campaign) = ACTION::LookupOK then begin
                                Validate("Campaign No.", Campaign."No.");
                                "Wizard Campaign Description" := Campaign.Description;
                            end;
                        end;
                    end;
                }
                field("Wizard Opportunity Description"; "Wizard Opportunity Description")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Opportunity';
                    Editable = WizardOpportunityDescriptionEd;
                    Importance = Additional;
                    Lookup = false;
                    TableRelation = Opportunity;
                    ToolTip = 'Specifies a description of the Opportunity that is related to the Task. The description is copied from the Campaign card.';

                    trigger OnAssistEdit()
                    var
                        Opp: Record Opportunity;
                    begin
                        if GetFilter("Opportunity No.") = '' then begin
                            if Opp.Get("Opportunity No.") then;
                            if PAGE.RunModal(0, Opp) = ACTION::LookupOK then begin
                                Validate("Opportunity No.", Opp."No.");
                                "Wizard Opportunity Description" := Opp.Description;
                            end;
                        end;
                    end;
                }
                field(SegmentDesc; "Segment Description")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Create Tasks for Segment Contacts';
                    Editable = SegmentDescEditable;
                    Importance = Additional;
                    Lookup = false;
                    TableRelation = "Segment Header";
                    ToolTip = 'Specifies a description of the Segment related to the Task. The description is copied from the Segment Card.';

                    trigger OnAssistEdit()
                    var
                        SegmentHeader: Record "Segment Header";
                    begin
                        if GetFilter("Segment No.") = '' then begin
                            if SegmentHeader.Get("Segment No.") then;
                            if PAGE.RunModal(0, SegmentHeader) = ACTION::LookupOK then begin
                                Validate("Segment No.", SegmentHeader."No.");
                                "Segment Description" := SegmentHeader.Description;
                            end;
                        end;
                    end;
                }
                field(Priority; Priority)
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Priority';
                    Importance = Additional;
                    ToolTip = 'Specifies the priority of the Task. There are three options:';
                }
                field(Location; Location)
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Location';
                    Enabled = LocationEnable;
                    Importance = Promoted;
                    ToolTip = 'Specifies the Location where the Meeting will take place.';
                    Visible = NOT IsSoftwareAsAService;
                }
            }
            group(MeetingAttendees)
            {
                Caption = 'Meeting Attendees';
                Visible = IsMeeting;
                part(AttendeeSubform; "Attendee Wizard Subform")
                {
                    ApplicationArea = RelationshipMgmt;
                    SubPageLink = "To-do No." = FIELD("No.");
                }
                group(MeetingInteraction)
                {
                    Caption = 'Interaction';
                    field("Send on finish"; "Send on finish")
                    {
                        ApplicationArea = RelationshipMgmt;
                        Caption = 'Send Invitation(s) on Finish';
                        ToolTip = 'Specifies if the meeting invitation task will be sent when the Create Task wizard is finished.';
                    }
                    field("Interaction Template Code"; "Interaction Template Code")
                    {
                        ApplicationArea = RelationshipMgmt;
                        Caption = 'Interaction Template';
                        TableRelation = "Interaction Template";
                        ToolTip = 'Specifies the code for the Interaction Template that you have selected.';

                        trigger OnValidate()
                        begin
                            ValidateInteractionTemplCode;
                            InteractionTemplateCodeOnAfter;
                        end;
                    }
                    field("Language Code"; "Language Code")
                    {
                        ApplicationArea = RelationshipMgmt;
                        Enabled = LanguageCodeEnable;
                        ToolTip = 'Specifies the language that is used when translating specified text on documents to foreign business partner, such as an item description on an order confirmation.';

                        trigger OnLookup(var Text: Text): Boolean
                        begin
                            LookupLanguageCode;
                        end;

                        trigger OnValidate()
                        begin
                            ValidateLanguageCode;
                        end;
                    }
                    field(Attachment; "Attachment No." > 0)
                    {
                        ApplicationArea = RelationshipMgmt;
                        AssistEdit = true;
                        Caption = 'Attachment';
                        Editable = false;
                        Enabled = AttachmentEnable;
                        ToolTip = 'Specifies if the linked attachment is inherited or unique.';

                        trigger OnAssistEdit()
                        begin
                            AssistEditAttachment;
                        end;
                    }
                }
            }
            group(RecurringOptions)
            {
                Caption = 'Recurring';
                field(Recurring; Recurring)
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Recurring Task';
                    ToolTip = 'Specifies that the Task occurs periodically.';

                    trigger OnValidate()
                    begin
                        RecurringOnAfterValidate;
                    end;
                }
                field("Recurring Date Interval"; "Recurring Date Interval")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Recurring Date Interval';
                    Enabled = RecurringDateIntervalEnable;
                    ToolTip = 'Specifies the date formula to assign automatically a recurring Task to a Salesperson or Team.';
                }
                field("Calc. Due Date From"; "Calc. Due Date From")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Calculate from Date';
                    Enabled = CalcDueDateFromEnable;
                    ToolTip = 'Specifies the date to use to calculate the date on which the next Task should be completed.';
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
                ToolTip = 'Finish the task.';
                Visible = IsOnMobile;

                trigger OnAction()
                begin
                    FinishPage;
                    CurrPage.Close;
                end;
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        EnableFields;
        WizardContactNameOnFormat(Format("Wizard Contact Name"));
    end;

    trigger OnInit()
    var
        EnvironmentInfo: Codeunit "Environment Information";
    begin
        AttachmentEnable := true;
        LanguageCodeEnable := true;
        CalcDueDateFromEnable := true;
        RecurringDateIntervalEnable := true;
        WizardContactNameEnable := true;
        AllDayEventEnable := true;
        LocationEnable := true;
        DurationEnable := true;
        EndingTimeEnable := true;
        StartTimeEnable := true;
        SalespersonCodeEnable := true;
        SalespersonCodeEditable := true;
        WizardOpportunityDescriptionEd := true;
        WizardCampaignDescriptionEdita := true;
        WizardContactNameEditable := true;
        TeamTaskEditable := true;
        IsSoftwareAsAService := EnvironmentInfo.IsSaaS;
    end;

    trigger OnOpenPage()
    begin
        IsOnMobile := ClientTypeManagement.GetCurrentClientType = CLIENTTYPE::Phone;

        WizardContactNameEditable := false;
        WizardCampaignDescriptionEdita := false;
        WizardOpportunityDescriptionEd := false;

        if SalesPurchPerson.Get(GetFilter("Salesperson Code")) then begin
            SalespersonCodeEditable := false;
            TeamTaskEditable := false;
        end;

        if "Segment Description" <> '' then
            SegmentDescEditable := false;

        IsMeeting := (Type = Type::Meeting);
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        if CloseAction in [ACTION::OK, ACTION::LookupOK] then
            FinishPage;
    end;

    var
        Text000: Label '(Multiple)';
        Text001: Label 'untitled';
        Cont: Record Contact;
        SalesPurchPerson: Record "Salesperson/Purchaser";
        Campaign: Record Campaign;
        Team: Record Team;
        Opp: Record Opportunity;
        SegHeader: Record "Segment Header";
        AttendeeTemp: Record Attendee temporary;
        ClientTypeManagement: Codeunit "Client Type Management";
        SalespersonFilter: Code[20];
        ContactFilter: Code[20];
        [InDataSet]
        TeamTaskEditable: Boolean;
        [InDataSet]
        WizardContactNameEditable: Boolean;
        [InDataSet]
        WizardCampaignDescriptionEdita: Boolean;
        [InDataSet]
        WizardOpportunityDescriptionEd: Boolean;
        [InDataSet]
        SalespersonCodeEditable: Boolean;
        [InDataSet]
        SegmentDescEditable: Boolean;
        IsMeeting: Boolean;
        IsOnMobile: Boolean;
        [InDataSet]
        SalespersonCodeEnable: Boolean;
        [InDataSet]
        StartTimeEnable: Boolean;
        [InDataSet]
        EndingTimeEnable: Boolean;
        [InDataSet]
        DurationEnable: Boolean;
        [InDataSet]
        LocationEnable: Boolean;
        [InDataSet]
        AllDayEventEnable: Boolean;
        [InDataSet]
        WizardContactNameEnable: Boolean;
        [InDataSet]
        RecurringDateIntervalEnable: Boolean;
        [InDataSet]
        CalcDueDateFromEnable: Boolean;
        [InDataSet]
        LanguageCodeEnable: Boolean;
        [InDataSet]
        AttachmentEnable: Boolean;
        IsSoftwareAsAService: Boolean;

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
        if Opp.Get(GetFilter("Opportunity No.")) then
            CaptionStr := CopyStr(CaptionStr + ' ' + Opp."No." + ' ' + Opp.Description, 1, MaxStrLen(CaptionStr));
        if SegHeader.Get(GetFilter("Segment No.")) then
            CaptionStr := CopyStr(CaptionStr + ' ' + SegHeader."No." + ' ' + SegHeader.Description, 1, MaxStrLen(CaptionStr));
        if CaptionStr = '' then
            CaptionStr := Text001;

        exit(CaptionStr);
    end;

    local procedure EnableFields()
    begin
        RecurringDateIntervalEnable := Recurring;
        CalcDueDateFromEnable := Recurring;

        if not Recurring then begin
            Evaluate("Recurring Date Interval", '');
            Clear("Calc. Due Date From");
        end;

        IsMeeting := Type = Type::Meeting;

        if IsMeeting then begin
            StartTimeEnable := not "All Day Event";
            EndingTimeEnable := not "All Day Event";
            DurationEnable := not "All Day Event";
            LocationEnable := true;
            AllDayEventEnable := true;
            LanguageCodeEnable := "Interaction Template Code" <> '';
            AttachmentEnable := "Interaction Template Code" <> '';
        end else begin
            StartTimeEnable := false;
            EndingTimeEnable := false;
            LocationEnable := false;
            DurationEnable := false;
            AllDayEventEnable := false;
        end;
    end;

    local procedure ValidateTypeField()
    begin
        if Type <> xRec.Type then
            if Type = Type::Meeting then begin
                ClearDefaultAttendeeInfo;
                AssignDefaultAttendeeInfo;
                LoadTempAttachment;
                if not "Team To-do" then
                    if "Salesperson Code" = '' then begin
                        if Cont.Get("Contact No.") then
                            Validate("Salesperson Code", Cont."Salesperson Code")
                        else
                            if Cont.Get("Contact Company No.") then
                                Validate("Salesperson Code", Cont."Salesperson Code");
                        if Campaign.Get(GetFilter("Campaign No.")) then
                            Validate("Salesperson Code", Campaign."Salesperson Code");
                        if Opp.Get(GetFilter("Opportunity No.")) then
                            Validate("Salesperson Code", Opp."Salesperson Code");
                        if SegHeader.Get(GetFilter("Segment No.")) then
                            Validate("Salesperson Code", SegHeader."Salesperson Code");
                        Modify;
                    end;
                GetAttendee(AttendeeTemp);
                CurrPage.AttendeeSubform.PAGE.SetAttendee(AttendeeTemp);
                CurrPage.AttendeeSubform.PAGE.SetTaskFilter(SalespersonFilter, ContactFilter);
                CurrPage.AttendeeSubform.PAGE.UpdateForm;
            end else begin
                ClearDefaultAttendeeInfo;
                CurrPage.AttendeeSubform.PAGE.GetAttendee(AttendeeTemp);
                SetAttendee(AttendeeTemp);
                SalespersonCodeEnable := false;
                WizardContactNameEnable := true;
            end;
        IsMeeting := (Type = Type::Meeting);
        TypeOnAfterValidate;
        CurrPage.Update;
    end;

    local procedure TypeOnAfterValidate()
    begin
        EnableFields;
    end;

    local procedure AllDayEventOnAfterValidate()
    begin
        EnableFields;
    end;

    local procedure RecurringOnAfterValidate()
    begin
        EnableFields;
    end;

    local procedure InteractionTemplateCodeOnAfter()
    begin
        EnableFields
    end;

    local procedure WizardContactNameOnFormat(Text: Text[1024])
    begin
        if SegHeader.Get(GetFilter("Segment No.")) then
            Text := Text000;
    end;

    local procedure FinishPage()
    begin
        CurrPage.AttendeeSubform.PAGE.GetAttendee(AttendeeTemp);
        SetAttendee(AttendeeTemp);

        CheckStatus;
        FinishWizard(false);
    end;
}

