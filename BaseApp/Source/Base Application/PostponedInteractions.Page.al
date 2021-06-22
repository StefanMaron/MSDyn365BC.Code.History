page 5082 "Postponed Interactions"
{
    Caption = 'Postponed Interactions';
    Editable = false;
    PageType = List;
    SourceTable = "Interaction Log Entry";
    SourceTableView = WHERE(Postponed = CONST(true));

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                Editable = false;
                ShowCaption = false;
                field("Attempt Failed"; "Attempt Failed")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies whether the interaction records an failed attempt to reach the contact. This field is not editable.';
                }
                field("Document Type"; "Document Type")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the type of document if there is one that the interaction log entry records. You cannot change the contents of this field.';
                    Visible = false;
                }
                field("Document No."; "Document No.")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the number of the document (if any) that the interaction log entry records.';
                    Visible = false;
                }
                field("Delivery Status"; "Delivery Status")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the status of the delivery of the attachment. There are three options:';
                    Visible = false;
                }
                field(Date; Date)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the date that you have entered in the Date field in the Create Interaction wizard or the Segment window when you created the interaction. The field is not editable.';
                }
                field("Time of Interaction"; "Time of Interaction")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the time when the interaction was created. This field is not editable.';
                    Visible = false;
                }
                field("Correspondence Type"; "Correspondence Type")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the type of correspondence of the attachment in the interaction template. This field is not editable.';
                    Visible = false;
                }
                field("Interaction Group Code"; "Interaction Group Code")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the code of the interaction group used to create this interaction. This field is not editable.';
                    Visible = false;
                }
                field("Interaction Template Code"; "Interaction Template Code")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the code for the interaction template used to create the interaction. This field is not editable.';
                }
                field(Description; Description)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the description of the interaction.';
                }
                field("""Attachment No."" <> 0"; "Attachment No." <> 0)
                {
                    ApplicationArea = RelationshipMgmt;
                    BlankZero = true;
                    Caption = 'Attachment';
                    ToolTip = 'Specifies if the linked attachment is inherited or unique.';

                    trigger OnAssistEdit()
                    begin
                        if "Attachment No." <> 0 then
                            OpenAttachment;
                    end;
                }
                field("Information Flow"; "Information Flow")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the direction of information flow recorded by the interaction. There are two options: Outbound (the information was received by your contact) and Inbound (the information was received by your company).';
                    Visible = false;
                }
                field("Initiated By"; "Initiated By")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies who initiated the interaction. There are two options: Us (the interaction was initiated by your company) and Them (the interaction was initiated by your contact).';
                    Visible = false;
                }
                field("Contact No."; "Contact No.")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the number of the contact involved in this interaction. This field is not editable.';
                }
                field("Contact Company No."; "Contact Company No.")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the number of the contact company.';
                    Visible = false;
                }
                field(Evaluation; Evaluation)
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the evaluation of the interaction. There are five options: Very Positive, Positive, Neutral, Negative, and Very Negative.';
                }
                field("Cost (LCY)"; "Cost (LCY)")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the cost of the interaction.';
                }
                field("Duration (Min.)"; "Duration (Min.)")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the duration of the interaction.';
                }
                field("Salesperson Code"; "Salesperson Code")
                {
                    ApplicationArea = Suite, RelationshipMgmt;
                    ToolTip = 'Specifies the code for the salesperson who carried out the interaction. This field is not editable.';
                }
                field("User ID"; "User ID")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the ID of the user who logged this entry. This field is not editable.';
                    Visible = false;

                    trigger OnDrillDown()
                    var
                        UserMgt: Codeunit "User Management";
                    begin
                        UserMgt.DisplayUserInformation("User ID");
                    end;
                }
                field("Segment No."; "Segment No.")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the number of the segment. This field is valid only for interactions created for segments, and is not editable.';
                    Visible = false;
                }
                field("Campaign No."; "Campaign No.")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the number of the campaign (if any) to which the interaction is linked. This field is not editable.';
                }
                field("Campaign Entry No."; "Campaign Entry No.")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the number of the campaign entry to which the interaction log entry is linked.';
                    Visible = false;
                }
                field("Campaign Response"; "Campaign Response")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies whether the interaction records a response to a campaign.';
                    Visible = false;
                }
                field("Campaign Target"; "Campaign Target")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies whether the interaction is applied to contacts that are part of the campaign target. This field is not editable.';
                    Visible = false;
                }
                field("Opportunity No."; "Opportunity No.")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the number of the opportunity to which the interaction is linked.';
                }
                field("To-do No."; "To-do No.")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the number of the task if the interaction has been created to complete a task. This field is not editable.';
                    Visible = false;
                }
                field("Interaction Language Code"; "Interaction Language Code")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the language code for the interaction for the interaction log. The code is copied from the language code of the interaction template, if one is specified.';
                    Visible = false;
                }
                field(Subject; Subject)
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the subject text that will be used for this interaction.';
                    Visible = false;
                }
                field("Contact Via"; "Contact Via")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the telephone number that you used when calling the contact.';
                    Visible = false;
                }
                field("Entry No."; "Entry No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the number of the entry, as assigned from the specified number series when the entry was created.';
                }
                field(Comment; Comment)
                {
                    ApplicationArea = Comments;
                    ToolTip = 'Specifies that a comment exists for this interaction log entry.';
                }
            }
            group(Control78)
            {
                ShowCaption = false;
                field("Contact Name"; "Contact Name")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Contact Name';
                    DrillDown = false;
                    ToolTip = 'Specifies the name of the contact for which an interaction has been logged.';
                }
                field("Contact Company Name"; "Contact Company Name")
                {
                    ApplicationArea = RelationshipMgmt;
                    DrillDown = false;
                    ToolTip = 'Specifies the name of the contact company for which an interaction has been logged.';
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
                Visible = true;
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
                action("Filter")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Filter';
                    Image = "Filter";
                    Promoted = true;
                    PromotedCategory = Process;
                    ToolTip = 'Apply a filter to view specific interaction log entries.';

                    trigger OnAction()
                    var
                        FilterPageBuilder: FilterPageBuilder;
                    begin
                        FilterPageBuilder.AddTable(TableName, DATABASE::"Interaction Log Entry");
                        FilterPageBuilder.SetView(TableName, GetView);

                        if GetFilter("Contact No.") = '' then
                            FilterPageBuilder.AddFieldNo(TableName, FieldNo("Contact No."));
                        if GetFilter("Contact Company No.") = '' then
                            FilterPageBuilder.AddFieldNo(TableName, FieldNo("Contact Company No."));

                        if FilterPageBuilder.RunModal then
                            SetView(FilterPageBuilder.GetView(TableName));
                    end;
                }
                action(ClearFilter)
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Clear Filter';
                    Image = ClearFilter;
                    Promoted = true;
                    PromotedCategory = Process;
                    ToolTip = 'Clear the applied filter on specific interaction log entries.';

                    trigger OnAction()
                    begin
                        Reset;
                        FilterGroup(2);
                        SetRange(Postponed, true);
                        FilterGroup(0);
                    end;
                }
                action("&Delete")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = '&Delete';
                    Image = Delete;
                    ToolTip = 'Delete the selected postponed interactions.';

                    trigger OnAction()
                    begin
                        if Confirm(Text001) then begin
                            CurrPage.SetSelectionFilter(InteractionLogEntry);
                            if not InteractionLogEntry.IsEmpty then
                                InteractionLogEntry.DeleteAll(true)
                            else
                                Delete(true);
                        end;
                    end;
                }
            }
            action("Show Attachments")
            {
                ApplicationArea = RelationshipMgmt;
                Caption = '&Show Attachments';
                Image = View;
                Promoted = true;
                PromotedCategory = Process;
                Scope = Repeater;
                ToolTip = 'Show attachments or related documents.';

                trigger OnAction()
                begin
                    if "Attachment No." <> 0 then
                        OpenAttachment
                    else
                        ShowDocument;
                end;
            }
            action(Resume)
            {
                ApplicationArea = RelationshipMgmt;
                Caption = '&Resume';
                Image = Start;
                Promoted = true;
                PromotedCategory = Process;
                Scope = Repeater;
                ToolTip = 'Resume a postponed interaction.';

                trigger OnAction()
                begin
                    if IsEmpty then
                        exit;

                    ResumeInteraction
                end;
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        CalcFields("Contact Name", "Contact Company Name");
    end;

    trigger OnOpenPage()
    begin
        SetCaption;
    end;

    var
        InteractionLogEntry: Record "Interaction Log Entry";
        Text001: Label 'Delete selected lines?';

    local procedure SetCaption()
    var
        Contact: Record Contact;
        Salesperson: Record "Salesperson/Purchaser";
        Task: Record "To-do";
        Opportunity: Record Opportunity;
    begin
        if Contact.Get("Contact Company No.") then
            CurrPage.Caption(CurrPage.Caption + ' - ' + Contact."Company No." + ' . ' + Contact."Company Name");
        if Contact.Get("Contact No.") then begin
            CurrPage.Caption(CurrPage.Caption + ' - ' + Contact."No." + ' . ' + Contact.Name);
            exit;
        end;
        if "Contact Company No." <> '' then
            exit;
        if Salesperson.Get("Salesperson Code") then begin
            CurrPage.Caption(CurrPage.Caption + ' - ' + "Salesperson Code" + ' . ' + Salesperson.Name);
            exit;
        end;
        if "Interaction Template Code" <> '' then begin
            CurrPage.Caption(CurrPage.Caption + ' - ' + "Interaction Template Code");
            exit;
        end;
        if Task.Get("To-do No.") then begin
            CurrPage.Caption(CurrPage.Caption + ' - ' + Task."No." + ' . ' + Task.Description);
            exit;
        end;
        if Opportunity.Get("Opportunity No.") then
            CurrPage.Caption(CurrPage.Caption + ' - ' + Opportunity."No." + ' . ' + Opportunity.Description);
    end;
}

