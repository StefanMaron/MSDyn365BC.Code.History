page 5077 "Create Interaction"
{
    Caption = 'Create Interaction';
    DataCaptionExpression = Caption();
    DeleteAllowed = false;
    InsertAllowed = false;
    LinksAllowed = false;
    PageType = Card;
    ShowFilter = false;
    SourceTable = "Segment Line";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("Wizard Contact Name"; Rec."Wizard Contact Name")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Contact';
                    Editable = IsContactEditable;
                    Lookup = false;
                    ShowMandatory = true;
                    ToolTip = 'Specifies the contact that you are interacting with.';

                    trigger OnAssistEdit()
                    var
                        Contact: Record Contact;
                    begin
                        if IsContactEditable then begin
                            if Contact.Get("Contact No.") then;
                            if PAGE.RunModal(0, Contact) = ACTION::LookupOK then
                                SetContactNo(Contact);
                        end;
                    end;

                    trigger OnValidate()
                    var
                        Contact: Record Contact;
                        FilterWithoutQuotes: Text;
                    begin
                        "Wizard Contact Name" := DelChr("Wizard Contact Name", '<>');
                        if "Wizard Contact Name" = "Contact Name" then
                            exit;
                        if "Wizard Contact Name" = '' then
                            Clear(Contact)
                        else begin
                            FilterWithoutQuotes := ConvertStr("Wizard Contact Name", '''', '?');
                            Contact.SetFilter(Name, '''@*' + FilterWithoutQuotes + '*''');
                            if not Contact.FindFirst() then
                                Clear(Contact);
                        end;
                        SetContactNo(Contact)
                    end;
                }
                field("Interaction Template Code"; Rec."Interaction Template Code")
                {
                    ApplicationArea = RelationshipMgmt;
                    Importance = Promoted;
                    NotBlank = true;
                    ShowMandatory = true;
                    ToolTip = 'Specifies the type of the interaction.';

                    trigger OnValidate()
                    begin
                        UpdateUIFlags();

                        if Campaign.Get("Campaign No.") then
                            "Campaign Description" := Campaign.Description;

                        if "Attachment No." <> xRec."Attachment No." then
                            AttachmentReload();
                    end;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Description';
                    Importance = Promoted;
                    NotBlank = true;
                    ShowMandatory = true;
                    ToolTip = 'Specifies what the interaction is about.';
                }
                field("Salesperson Code"; Rec."Salesperson Code")
                {
                    ApplicationArea = Suite, RelationshipMgmt;
                    Caption = 'Salesperson';
                    Editable = SalespersonCodeEditable;
                    ShowMandatory = true;
                    ToolTip = 'Specifies the salesperson who is responsible for this interaction.';
                }
                field("Language Code"; Rec."Language Code")
                {
                    ApplicationArea = RelationshipMgmt;
                    Enabled = IsMainInfoSet;
                    ToolTip = 'Specifies the language that is used when translating specified text on documents to foreign business partner, such as an item description on an order confirmation.';

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        LanguageCodeOnLookup();
                        if "Attachment No." <> xRec."Attachment No." then
                            AttachmentReload();
                    end;

                    trigger OnValidate()
                    begin
                        if "Attachment No." <> xRec."Attachment No." then
                            AttachmentReload();
                    end;
                }
            }
            group(BodyContent)
            {
                Caption = 'Content';
                Visible = HTMLAttachment;
                field(HTMLContentBodyText; HTMLContentBodyText)
                {
                    ApplicationArea = RelationshipMgmt;
                    MultiLine = true;
                    ShowCaption = false;

                    trigger OnValidate()
                    begin
                        UpdateContentBodyTextInCustomLayoutAttachment(HTMLContentBodyText);
                    end;
                }
            }
            group(InteractionDetails)
            {
                Caption = 'Interaction Details';
                Enabled = IsMainInfoSet;
                field("Correspondence Type"; Rec."Correspondence Type")
                {
                    ApplicationArea = RelationshipMgmt;
                    Enabled = IsMainInfoSet;
                    Importance = Additional;
                    ToolTip = 'Specifies the type of correspondence for the interaction. NOTE: If you use the Web client, you must not select the Hard Copy option because printing is not possible from the web client.';

                    trigger OnValidate()
                    begin
                        ValidateCorrespondenceType();
                    end;
                }
                field(Date; Date)
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Date of Interaction';
                    Enabled = IsMainInfoSet;
                    Importance = Additional;
                    ToolTip = 'Specifies the date when the interaction took place.';
                }
                field("Time of Interaction"; Rec."Time of Interaction")
                {
                    ApplicationArea = RelationshipMgmt;
                    Enabled = IsMainInfoSet;
                    Importance = Additional;
                    ToolTip = 'Specifies the time when the interaction took place';
                }
                field("Information Flow"; Rec."Information Flow")
                {
                    ApplicationArea = RelationshipMgmt;
                    Enabled = IsMainInfoSet;
                    Importance = Additional;
                    ToolTip = 'Specifies the direction of the interaction, inbound or outbound.';
                }
                field("Initiated By"; Rec."Initiated By")
                {
                    ApplicationArea = RelationshipMgmt;
                    Enabled = IsMainInfoSet;
                    Importance = Additional;
                    ToolTip = 'Specifies if the interaction was initiated by your company or by one of your contacts. The Us option indicates that your company was the initiator; the Them option indicates that a contact was the initiator.';
                }
                field(Evaluation; Evaluation)
                {
                    ApplicationArea = RelationshipMgmt;
                    Enabled = IsMainInfoSet;
                    Importance = Additional;
                    ToolTip = 'Specifies the evaluation of the interaction involving the contact in the segment.';
                }
                field("Interaction Successful"; Rec."Interaction Successful")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Was Successful';
                    Enabled = IsMainInfoSet;
                    Importance = Additional;
                    ToolTip = 'Specifies if the interaction was successful. Clear this check box to indicate that the interaction was not a success.';
                }
                field("Cost (LCY)"; Rec."Cost (LCY)")
                {
                    ApplicationArea = RelationshipMgmt;
                    Enabled = IsMainInfoSet;
                    Importance = Additional;
                    ToolTip = 'Specifies the cost of the interaction with the contact that this segment line applies to.';
                }
                field("Duration (Min.)"; Rec."Duration (Min.)")
                {
                    ApplicationArea = RelationshipMgmt;
                    Enabled = IsMainInfoSet;
                    Importance = Additional;
                    ToolTip = 'Specifies the duration of the interaction with the contact.';
                }
                field("Campaign Description"; Rec."Campaign Description")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Campaign';
                    Editable = CampaignDescriptionEditable;
                    Enabled = IsMainInfoSet;
                    Importance = Promoted;
                    Lookup = false;
                    TableRelation = Campaign;
                    ToolTip = 'Specifies the campaign that is related to the segment. The description is copied from the campaign card.';

                    trigger OnAssistEdit()
                    var
                        Campaign: Record Campaign;
                    begin
                        if GetFilter("Campaign No.") = '' then begin
                            if Campaign.Get("Campaign No.") then;
                            if PAGE.RunModal(0, Campaign) = ACTION::LookupOK then begin
                                Validate("Campaign No.", Campaign."No.");
                                "Campaign Description" := Campaign.Description;
                            end;
                        end;
                    end;
                }
                field("Campaign Target"; Rec."Campaign Target")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Contact is Targeted';
                    Enabled = IsMainInfoSet;
                    Importance = Additional;
                    ToolTip = 'Specifies that the segment involved in this interaction is the target of a campaign. This is used to measure the response rate of a campaign.';
                }
                field("Campaign Response"; Rec."Campaign Response")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Campaign Response';
                    Enabled = IsMainInfoSet;
                    Importance = Additional;
                    ToolTip = 'Specifies that the interaction created for the segment is the response to a campaign. For example, coupons that are sent as a response to a campaign.';
                }
                field("Opportunity Description"; Rec."Opportunity Description")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Opportunity';
                    Editable = OpportunityDescriptionEditable;
                    Enabled = IsMainInfoSet;
                    Importance = Promoted;
                    Lookup = false;
                    TableRelation = Opportunity;
                    ToolTip = 'Specifies a description of the opportunity that is related to the segment. The description is copied from the opportunity card.';

                    trigger OnAssistEdit()
                    var
                        Opportunity: Record Opportunity;
                    begin
                        FilterContactCompanyOpportunities(Opportunity);
                        if PAGE.RunModal(0, Opportunity) = ACTION::LookupOK then begin
                            Validate("Opportunity No.", Opportunity."No.");
                            "Opportunity Description" := Opportunity.Description;
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
            action(Preview)
            {
                ApplicationArea = RelationshipMgmt;
                Caption = 'Preview';
                Enabled = HTMLAttachment;
                Image = PreviewChecks;
                ToolTip = 'Test the setup of the interaction.';
                Visible = HTMLAttachment;

                trigger OnAction()
                begin
                    PreviewSegLineHTMLContent();
                end;
            }
            action(Finish)
            {
                ApplicationArea = RelationshipMgmt;
                Enabled = IsMainInfoSet;
                Image = Approve;
                InFooterBar = true;
                Visible = IsOnMobile;

                trigger OnAction()
                begin
                    FinishSegLineWizard(true);
                    IsFinished := true;
                    CurrPage.Close();
                end;
            }
        }
        area(navigation)
        {
            action("Co&mments")
            {
                ApplicationArea = RelationshipMgmt;
                Caption = 'Co&mments';
                Image = ViewComments;
                ToolTip = 'View or add comments for the record.';

                trigger OnAction()
                begin
                    ShowComment();
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref("Co&mments_Promoted"; "Co&mments")
                {
                }
                actionref(Preview_Promoted; Preview)
                {
                }
                actionref(Finish_Promoted; Finish)
                {
                }
            }
        }
    }

    trigger OnInit()
    begin
        SalespersonCodeEditable := true;
        OpportunityDescriptionEditable := true;
        CampaignDescriptionEditable := true;
        IsOnMobile := ClientTypeManagement.GetCurrentClientType() = CLIENTTYPE::Phone;
    end;

    trigger OnOpenPage()
    begin
        CampaignDescriptionEditable := false;
        OpportunityDescriptionEditable := false;
        SetContactEditable();
        UpdateUIFlags();

        if SalesPurchPerson.Get(GetFilter("Salesperson Code")) then
            SalespersonCodeEditable := false;

        AttachmentReload();

        IsFinished := false;
        CurrPage.Update(false);
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        if IsFinished then
            exit;

        FinishSegLineWizard(CloseAction in [ACTION::OK, ACTION::LookupOK]);
    end;

    var
        SalesPurchPerson: Record "Salesperson/Purchaser";
        Campaign: Record Campaign;
        Task: Record "To-do";
        ClientTypeManagement: Codeunit "Client Type Management";
        HTMLContentBodyText: Text;
        [InDataSet]
        CampaignDescriptionEditable: Boolean;
        [InDataSet]
        OpportunityDescriptionEditable: Boolean;
        [InDataSet]
        SalespersonCodeEditable: Boolean;
        HTMLAttachment: Boolean;
        UntitledTxt: Label 'untitled';
        IsOnMobile: Boolean;
        IsFinished: Boolean;
        IsContactEditable: Boolean;

    protected var
        IsMainInfoSet: Boolean;

    procedure Caption(): Text
    var
        Contact: Record Contact;
        CaptionStr: Text;
    begin
        if Contact.Get(GetFilter("Contact Company No.")) then
            CaptionStr := CopyStr(Contact."No." + ' ' + Contact.Name, 1, MaxStrLen(CaptionStr));
        if Contact.Get(GetFilter("Contact No.")) then
            CaptionStr := CopyStr(CaptionStr + ' ' + Contact."No." + ' ' + Contact.Name, 1, MaxStrLen(CaptionStr));
        if SalesPurchPerson.Get(GetFilter("Salesperson Code")) then
            CaptionStr := CopyStr(CaptionStr + ' ' + SalesPurchPerson.Code + ' ' + SalesPurchPerson.Name, 1, MaxStrLen(CaptionStr));
        if Campaign.Get(GetFilter("Campaign No.")) then
            CaptionStr := CopyStr(CaptionStr + ' ' + Campaign."No." + ' ' + Campaign.Description, 1, MaxStrLen(CaptionStr));
        if Task.Get(GetFilter("To-do No.")) then
            CaptionStr := CopyStr(CaptionStr + ' ' + Task."No." + ' ' + Task.Description, 1, MaxStrLen(CaptionStr));

        if CaptionStr = '' then
            CaptionStr := UntitledTxt;

        OnAfterCaption(Rec, CaptionStr);
        exit(CaptionStr);
    end;

    procedure UpdateUIFlags()
    begin
        IsMainInfoSet := "Interaction Template Code" <> '';
    end;

    procedure AttachmentReload()
    begin
        LoadSegLineAttachment(true);
        HTMLAttachment := IsHTMLAttachment();
        if HTMLAttachment then
            HTMLContentBodyText := LoadContentBodyTextFromCustomLayoutAttachment();
    end;

    local procedure SetContactNo(Contact: Record Contact)
    begin
        Validate("Contact No.", Contact."No.");
        "Wizard Contact Name" := Contact.Name;
    end;

    local procedure SetContactEditable()
    begin
        IsContactEditable := (GetFilter("Contact No.") = '') and (GetFilter("Contact Company No.") = '');

        OnAfterSetContactEditable(Rec, IsContactEditable);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCaption(var SegmentLine: Record "Segment Line"; var CaptionStr: Text[260])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetContactEditable(var SegmentLine: Record "Segment Line"; var IsContactEditable: Boolean)
    begin
    end;
}

