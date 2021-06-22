page 5199 "Attendee Scheduling"
{
    Caption = 'Attendee Scheduling';
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = Document;
    SourceTable = "To-do";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("No."; "No.")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
                }
                field(Description; Description)
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Specifies the description of the task.';
                }
                field(Location; Location)
                {
                    ApplicationArea = Location;
                    Editable = false;
                    ToolTip = 'Specifies the location where the meeting will take place.';
                }
                field("Salesperson Code"; "Salesperson Code")
                {
                    ApplicationArea = Suite, RelationshipMgmt;
                    Editable = false;
                    ToolTip = 'Specifies the code of the salesperson assigned to the task.';
                }
                field(Type; Type)
                {
                    ApplicationArea = RelationshipMgmt;
                    Editable = false;
                    ToolTip = 'Specifies the type of the task.';
                }
                field(Status; Status)
                {
                    ApplicationArea = RelationshipMgmt;
                    Editable = false;
                    ToolTip = 'Specifies the status of the task. There are five options: Not Started, In Progress, Completed, Waiting and Postponed.';
                }
                field(Priority; Priority)
                {
                    ApplicationArea = RelationshipMgmt;
                    Editable = false;
                    ToolTip = 'Specifies the priority of the task.';
                }
            }
            part(AttendeeSubform; "Attendee Subform")
            {
                ApplicationArea = Basic, Suite;
                SubPageLink = "To-do No." = FIELD("Organizer To-do No.");
                SubPageView = SORTING("To-do No.", "Line No.");
            }
            group(Interaction)
            {
                Caption = 'Interaction';
                field("Interaction Template Code"; "Interaction Template Code")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the code for the interaction template that you have selected.';

                    trigger OnValidate()
                    begin
                        InteractionTemplateCodeOnAfter;
                    end;
                }
                field("Language Code"; "Language Code")
                {
                    ApplicationArea = RelationshipMgmt;
                    Enabled = LanguageCodeEnable;
                    ToolTip = 'Specifies the language that is used when translating specified text on documents to foreign business partner, such as an item description on an order confirmation.';
                }
                field(Subject; Subject)
                {
                    ApplicationArea = RelationshipMgmt;
                    Enabled = SubjectEnable;
                    ToolTip = 'Specifies the subject of the task. The subject is used for e-mail messages or Outlook meetings that you create.';
                }
                field(Attachment; "Attachment No." > 0)
                {
                    ApplicationArea = RelationshipMgmt;
                    AssistEdit = true;
                    Caption = 'Attachment';
                    Enabled = AttachmentEnable;
                    ToolTip = 'Specifies if the linked attachment is inherited or unique.';

                    trigger OnAssistEdit()
                    begin
                        MaintainAttachment;
                    end;
                }
                field("Unit Cost (LCY)"; "Unit Cost (LCY)")
                {
                    ApplicationArea = RelationshipMgmt;
                    Enabled = UnitCostLCYEnable;
                    ToolTip = 'Specifies the cost, in LCY, of one unit of the item or resource on the line.';
                }
                field("Unit Duration (Min.)"; "Unit Duration (Min.)")
                {
                    ApplicationArea = RelationshipMgmt;
                    Enabled = UnitDurationMinEnable;
                    ToolTip = 'Specifies the duration of the interaction.';
                }
            }
        }
        area(factboxes)
        {
            systempart(Control1900383207; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(Control1905767507; Notes)
            {
                ApplicationArea = Notes;
                Visible = false;
            }
        }
    }

    actions
    {
        area(processing)
        {
            group(Functions)
            {
                Caption = 'F&unctions';
                Image = "Action";
                group(Action33)
                {
                    Caption = 'Attachment';
                    Image = Attachments;
                    action(Open)
                    {
                        ApplicationArea = RelationshipMgmt;
                        Caption = 'Open';
                        Image = Edit;
                        ShortCutKey = 'Return';
                        ToolTip = 'Open the card for the selected record.';

                        trigger OnAction()
                        begin
                            OpenAttachment(not CurrPage.Editable);
                        end;
                    }
                    action(Create)
                    {
                        ApplicationArea = RelationshipMgmt;
                        Caption = 'Create';
                        Image = New;
                        ToolTip = 'Create an attachment.';

                        trigger OnAction()
                        begin
                            CreateAttachment(not CurrPage.Editable);
                        end;
                    }
                    action(Import)
                    {
                        ApplicationArea = RelationshipMgmt;
                        Caption = 'Import';
                        Image = Import;
                        ToolTip = 'Import an attachment.';

                        trigger OnAction()
                        begin
                            ImportAttachment;
                        end;
                    }
                    action(Export)
                    {
                        ApplicationArea = RelationshipMgmt;
                        Caption = 'Export';
                        Image = Export;
                        ToolTip = 'Export an attachment.';

                        trigger OnAction()
                        begin
                            ExportAttachment;
                        end;
                    }
                    action(Remove)
                    {
                        ApplicationArea = RelationshipMgmt;
                        Caption = 'Remove';
                        Image = Cancel;
                        ToolTip = 'Remove an attachment.';

                        trigger OnAction()
                        begin
                            RemoveAttachment(true);
                        end;
                    }
                }
                action("Send Invitations")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Send Invitations';
                    Image = DistributionGroup;
                    ToolTip = 'Send invitation to the attendee.';
                    Visible = not IsSaas;

                    trigger OnAction()
                    begin
                        SendMAPIInvitations(Rec, false);
                    end;
                }
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        EnableFields
    end;

    trigger OnAfterGetRecord()
    begin
        if "No." <> "Organizer To-do No." then
            CurrPage.Editable := false;

        if Closed then
            CurrPage.Editable := false;
    end;

    trigger OnInit()
    begin
        UnitDurationMinEnable := true;
        UnitCostLCYEnable := true;
        AttachmentEnable := true;
        SubjectEnable := true;
        LanguageCodeEnable := true;
        IsSaas := EnvironmentInfo.IsSaaS();
    end;

    var
        EnvironmentInfo: Codeunit "Environment Information";
        IsSaas: Boolean;
        [InDataSet]
        LanguageCodeEnable: Boolean;
        [InDataSet]
        SubjectEnable: Boolean;
        [InDataSet]
        AttachmentEnable: Boolean;
        [InDataSet]
        UnitCostLCYEnable: Boolean;
        [InDataSet]
        UnitDurationMinEnable: Boolean;

    local procedure MaintainAttachment()
    begin
        if "Interaction Template Code" = '' then
            exit;

        if "Attachment No." <> 0 then begin
            if not CurrPage.Editable then begin
                CurrPage.Editable := true;
                OpenAttachment(true);
                CurrPage.Editable := false;
            end else
                OpenAttachment(false);
        end else
            CreateAttachment(not CurrPage.Editable);
    end;

    local procedure EnableFields()
    begin
        LanguageCodeEnable := "Interaction Template Code" <> '';
        SubjectEnable := "Interaction Template Code" <> '';
        AttachmentEnable := "Interaction Template Code" <> '';
        UnitCostLCYEnable := "Interaction Template Code" <> '';
        UnitDurationMinEnable := "Interaction Template Code" <> ''
    end;

    local procedure InteractionTemplateCodeOnAfter()
    begin
        EnableFields
    end;
}

