page 5092 "Segment Subform"
{
    AutoSplitKey = true;
    Caption = 'Lines';
    LinksAllowed = false;
    PageType = ListPart;
    SourceTable = "Segment Line";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Contact No."; Rec."Contact No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the number of the contact to which this segment line applies.';

                    trigger OnValidate()
                    begin
                        ContactNoOnAfterValidate();
                    end;
                }
                field("Correspondence Type"; Rec."Correspondence Type")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the type of correspondence for the interaction. NOTE: If you use the Web client, you must not select the Hard Copy option because printing is not possible from the web client.';
                }
                field("Send Word Doc. As Attmt."; Rec."Send Word Doc. As Attmt.")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies that the Microsoft Word document that is linked to that segment line should be sent as an attachment in the e-mail message.';
                    Visible = false;
                }
                field("Contact Alt. Address Code"; Rec."Contact Alt. Address Code")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the code of the contact''s alternate address to use for this interaction.';
                    Visible = false;
                }
                field("Contact Company Name"; Rec."Contact Company Name")
                {
                    ApplicationArea = RelationshipMgmt;
                    DrillDown = false;
                    ToolTip = 'Specifies the name of the company for which the contact works. If the contact is a company, this field contains the company''s name.';
                }
                field("Contact Name"; Rec."Contact Name")
                {
                    ApplicationArea = RelationshipMgmt;
                    DrillDown = false;
                    ToolTip = 'Specifies the name of the contact to which the segment line applies. The program automatically fills in this field when you fill in the Contact No. field on the line.';
                }
                field(Description; Description)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the description of the segment line.';
                }
                field("Salesperson Code"; Rec."Salesperson Code")
                {
                    ApplicationArea = Suite, RelationshipMgmt;
                    ToolTip = 'Specifies the code of the salesperson responsible for this segment line and/or interaction.';
                }
                field("Interaction Template Code"; Rec."Interaction Template Code")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the interaction template code of the interaction involving the contact on this segment line.';
                }
                field("Language Code"; Rec."Language Code")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the language that is used when translating specified text on documents to foreign business partner, such as an item description on an order confirmation.';

                    trigger OnValidate()
                    begin
                        LanguageCodeOnAfterValidate();
                    end;
                }
                field(Subject; Subject)
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the subject of the segment line. The text in the field is used as the subject in e-mails and Word documents.';
                }
                field(Evaluation; Evaluation)
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the evaluation of the interaction involving the contact in the segment.';
                }
                field("Cost (LCY)"; Rec."Cost (LCY)")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the cost of the interaction with the contact that this segment line applies to.';
                }
                field("Duration (Min.)"; Rec."Duration (Min.)")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the duration of the interaction with the contact to which this segment line applies.';
                }
                field("Initiated By"; Rec."Initiated By")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies whether the interaction recorded for this segment line was initiated by your company or by one of your contacts. The Us option indicates that your company was the initiator; the Them option indicates that a contact was the initiator.';
                    Visible = false;
                }
                field("Information Flow"; Rec."Information Flow")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the direction of the information that is part of the interaction created for this segment line. There are two options: Inbound and Outbound.';
                    Visible = false;
                }
                field("Campaign No."; Rec."Campaign No.")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the number of the campaign for which the segment line has been created.';
                    Visible = false;
                }
                field("Campaign Target"; Rec."Campaign Target")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies that the segment involved in this interaction is the target of a campaign. This is used to measure the response rate of a campaign.';
                    Visible = false;
                }
                field("Campaign Response"; Rec."Campaign Response")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies that the interaction created for the segment is the response to a campaign. For example, coupons that are sent as a response to a campaign.';
                    Visible = false;
                }
                field(AttachmentText; AttachmentText())
                {
                    ApplicationArea = RelationshipMgmt;
                    AssistEdit = true;
                    Caption = 'Attachment';
                    Editable = false;
                    ToolTip = 'Specifies if the linked attachment is inherited or unique.';

                    trigger OnAssistEdit()
                    begin
                        CurrPage.SaveRecord();
                        MaintainSegLineAttachment();
                        CurrPage.Update(false);
                    end;
                }
                field("Word Template Code"; Rec."Word Template Code")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Word Template Code';
                    ToolTip = 'Specifies the Word Template code to use for merging.';
                }

                field("Contact Via"; Rec."Contact Via")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the telephone number you used when calling the contact, or the e-mail address you used when sending an e-mail to the contact.';
                    Visible = false;
                }
                field("Contact Phone No."; Rec."Contact Phone No.")
                {
                    ApplicationArea = RelationshipMgmt;
                    DrillDown = false;
                    ToolTip = 'Specifies the telephone number of the contact to whom the segment line applies. The number will be filled in for you if you choose a contact in the Contact No. field on the line.';
                }
                field("Contact Mobile Phone No."; Rec."Contact Mobile Phone No.")
                {
                    ApplicationArea = RelationshipMgmt;
                    DrillDown = false;
                    ToolTip = 'Specifies the mobile telephone number of the contact to whom the segment line applies. The number will be filled in for you if you choose a contact in the Contact No. field on the line.';
                }
                field("Contact E-Mail"; Rec."Contact Email")
                {
                    ApplicationArea = RelationshipMgmt;
                    DrillDown = false;
                    ToolTip = 'Specifies the email address of the contact to whom the segment line applies. The address will be filled in for you if you choose a contact in the Contact No. field on the line.';
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            group(Line)
            {
                Caption = 'Line';
                Image = Line;
                group(Attachment)
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
                            TestField("Interaction Template Code");
                            OpenSegLineAttachment();
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
                            CreateSegLineAttachment();
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
                            TestField("Interaction Template Code");
                            ImportSegLineAttachment();
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
                            TestField("Interaction Template Code");
                            ExportSegLineAttachment();
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
                            TestField("Interaction Template Code");
                            RemoveAttachment();
                        end;
                    }
                }
            }
            group("F&unctions")
            {
                Caption = 'F&unctions';
                Image = "Action";
                action("Make &Phone Call")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Make &Phone Call';
                    Image = Calls;
                    ToolTip = 'Call the selected contact.';

                    trigger OnAction()
                    begin
                        CreatePhoneCall();
                    end;
                }
            }
        }
    }

    trigger OnDeleteRecord(): Boolean
    begin
        if "Contact No." <> '' then begin
            SegCriteriaManagement.DeleteContact("Segment No.", "Contact No.");
            SegmentHistoryMgt.DeleteLine("Segment No.", "Contact No.", "Line No.");
        end;
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    begin
        if "Contact No." <> '' then begin
            SegCriteriaManagement.InsertContact("Segment No.", "Contact No.");
            SegmentHistoryMgt.InsertLine("Segment No.", "Contact No.", "Line No.");
        end;
    end;

    trigger OnModifyRecord(): Boolean
    begin
        if "Contact No." <> xRec."Contact No." then begin
            if xRec."Contact No." <> '' then begin
                SegCriteriaManagement.DeleteContact("Segment No.", xRec."Contact No.");
                SegmentHistoryMgt.DeleteLine("Segment No.", xRec."Contact No.", "Line No.");
            end;
            if "Contact No." <> '' then begin
                SegCriteriaManagement.InsertContact("Segment No.", "Contact No.");
                SegmentHistoryMgt.InsertLine("Segment No.", "Contact No.", "Line No.");
            end;
        end;
    end;

    var
        SegmentHistoryMgt: Codeunit SegHistoryManagement;
        SegCriteriaManagement: Codeunit SegCriteriaManagement;

    procedure UpdateForm()
    begin
        CurrPage.Update(false);
    end;

    local procedure ContactNoOnAfterValidate()
    begin
        CurrPage.Update(true);
    end;

    local procedure LanguageCodeOnAfterValidate()
    begin
        CurrPage.Update(false);
    end;
}

