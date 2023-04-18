table 5065 "Interaction Log Entry"
{
    Caption = 'Interaction Log Entry';
    DrillDownPageID = "Interaction Log Entries";
    LookupPageID = "Interaction Log Entries";
    ReplicateData = true;
    Permissions = TableData "Interaction Log Entry" = rimd;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
        }
        field(2; "Contact No."; Code[20])
        {
            Caption = 'Contact No.';
            TableRelation = Contact;
        }
        field(3; "Contact Company No."; Code[20])
        {
            Caption = 'Contact Company No.';
            TableRelation = Contact WHERE(Type = CONST(Company));
        }
        field(4; Date; Date)
        {
            Caption = 'Date';
        }
        field(5; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(6; "Information Flow"; Option)
        {
            Caption = 'Information Flow';
            OptionCaption = ' ,Outbound,Inbound';
            OptionMembers = " ",Outbound,Inbound;
        }
        field(7; "Initiated By"; Option)
        {
            Caption = 'Initiated By';
            OptionCaption = ' ,Us,Them';
            OptionMembers = " ",Us,Them;
        }
        field(8; "Attachment No."; Integer)
        {
            Caption = 'Attachment No.';
            TableRelation = Attachment;
        }
        field(9; "Cost (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Cost (LCY)';
            Editable = false;
        }
        field(10; "Duration (Min.)"; Decimal)
        {
            Caption = 'Duration (Min.)';
            DecimalPlaces = 0 : 0;
            Editable = false;
        }
        field(11; "User ID"; Code[50])
        {
            Caption = 'User ID';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = User."User Name";
            //This property is currently not supported
            //TestTableRelation = false;
        }
        field(12; "Interaction Group Code"; Code[10])
        {
            Caption = 'Interaction Group Code';
            TableRelation = "Interaction Group";
        }
        field(13; "Interaction Template Code"; Code[10])
        {
            Caption = 'Interaction Template Code';
            TableRelation = "Interaction Template";
        }
        field(14; "Campaign No."; Code[20])
        {
            Caption = 'Campaign No.';
            TableRelation = Campaign;
        }
        field(15; "Campaign Entry No."; Integer)
        {
            Caption = 'Campaign Entry No.';
            TableRelation = "Campaign Entry" WHERE("Campaign No." = FIELD("Campaign No."));
        }
        field(16; "Campaign Response"; Boolean)
        {
            Caption = 'Campaign Response';
        }
        field(17; "Campaign Target"; Boolean)
        {
            Caption = 'Campaign Target';
        }
        field(18; "Segment No."; Code[20])
        {
            Caption = 'Segment No.';
        }
        field(19; Evaluation; Enum "Interaction Evaluation")
        {
            Caption = 'Evaluation';
            Editable = false;
        }
        field(20; "Time of Interaction"; Time)
        {
            Caption = 'Time of Interaction';
        }
        field(21; "Attempt Failed"; Boolean)
        {
            Caption = 'Attempt Failed';
        }
        field(23; "To-do No."; Code[20])
        {
            Caption = 'Task No.';
            TableRelation = "To-do";
        }
        field(24; "Salesperson Code"; Code[20])
        {
            Caption = 'Salesperson Code';
            TableRelation = "Salesperson/Purchaser";
        }
        field(25; "Delivery Status"; Enum "Interaction Delivery Status")
        {
            Caption = 'Delivery Status';
        }
        field(26; Canceled; Boolean)
        {
            Caption = 'Canceled';
        }
        field(27; "Correspondence Type"; Enum "Correspondence Type")
        {
            Caption = 'Correspondence Type';
        }
        field(28; "Contact Alt. Address Code"; Code[10])
        {
            Caption = 'Contact Alt. Address Code';
            TableRelation = "Contact Alt. Address".Code WHERE("Contact No." = FIELD("Contact No."));
        }
        field(29; "Logged Segment Entry No."; Integer)
        {
            Caption = 'Logged Segment Entry No.';
            TableRelation = "Logged Segment";
        }
        field(30; "Document Type"; Enum "Interaction Log Entry Document Type")
        {
            Caption = 'Document Type';
        }
        field(31; "Document No."; Code[20])
        {
            Caption = 'Document No.';
            //This property is currently not supported
            //TestTableRelation = false;
        }
        field(32; "Version No."; Integer)
        {
            Caption = 'Version No.';
        }
        field(33; "Doc. No. Occurrence"; Integer)
        {
            Caption = 'Doc. No. Occurrence';
        }
        field(34; "Contact Via"; Text[80])
        {
            Caption = 'Contact Via';
        }
        field(35; "Send Word Docs. as Attmt."; Boolean)
        {
            Caption = 'Send Word Docs. as Attmt.';
        }
        field(36; "Interaction Language Code"; Code[10])
        {
            Caption = 'Interaction Language Code';
            TableRelation = Language;
        }
        field(37; "E-Mail Logged"; Boolean)
        {
            Caption = 'Email Logged';
        }
        field(38; Subject; Text[100])
        {
            Caption = 'Subject';
        }
        field(39; "Contact Name"; Text[100])
        {
            CalcFormula = Lookup(Contact.Name WHERE("No." = FIELD("Contact No.")));
            Caption = 'Contact Name';
            Editable = false;
            FieldClass = FlowField;
        }
        field(40; "Contact Company Name"; Text[100])
        {
            CalcFormula = Lookup(Contact.Name WHERE("No." = FIELD("Contact Company No."),
                                                     Type = CONST(Company)));
            Caption = 'Contact Company Name';
            Editable = false;
            FieldClass = FlowField;
        }
        field(43; Comment; Boolean)
        {
            CalcFormula = Exist("Inter. Log Entry Comment Line" WHERE("Entry No." = FIELD("Entry No.")));
            Caption = 'Comment';
            Editable = false;
            FieldClass = FlowField;
        }
        field(44; "Opportunity No."; Code[20])
        {
            Caption = 'Opportunity No.';
            TableRelation = Opportunity;
        }
        field(45; Postponed; Boolean)
        {
            Caption = 'Postponed';
        }
        field(46; "Word Template Code"; Code[30])
        {
            DataClassification = CustomerContent;
        }
    }

    keys
    {
        key(Key1; "Entry No.")
        {
            Clustered = true;
        }
        key(Key2; "Contact Company No.", "Contact No.", Date, Postponed)
        {
        }
        key(Key3; "Contact Company No.", Date, "Contact No.", Canceled, "Initiated By", "Attempt Failed", Postponed)
        {
        }
        key(Key4; "Interaction Group Code", Date)
        {
        }
        key(Key5; "Interaction Group Code", Canceled, Date, Postponed)
        {
        }
        key(Key6; "Interaction Template Code", Date)
        {
        }
        key(Key7; "Interaction Template Code", Canceled, Date, Postponed)
        {
            IncludedFields = "Cost (LCY)", "Duration (Min.)";
        }
        key(Key8; Canceled, "Campaign No.", "Campaign Entry No.", Date, Postponed)
        {
        }
        key(Key9; "Campaign No.", "Campaign Entry No.", Date, Postponed)
        {
        }
        key(Key10; "Salesperson Code", Date, Postponed)
        {
        }
        key(Key11; Canceled, "Salesperson Code", Date, Postponed)
        {
            IncludedFields = "Cost (LCY)", "Duration (Min.)";
        }
        key(Key12; "Logged Segment Entry No.", Postponed)
        {
        }
        key(Key13; "Attachment No.")
        {
        }
        key(Key14; "To-do No.", Date)
        {
        }
        key(Key15; "Contact No.", "Correspondence Type", "E-Mail Logged", Subject, Postponed)
        {
        }
        key(Key16; "Campaign No.", "Campaign Target")
        {
        }
        key(Key17; "Campaign No.", "Contact Company No.", "Campaign Target", Postponed)
        {
        }
        key(Key18; "Opportunity No.", Date)
        {
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "Entry No.", Description, "Contact No.", Date)
        {
        }
        fieldgroup(Brick; "Salesperson Code", Description, Date, "Contact Name", "Contact Company Name")
        {
        }
    }

    trigger OnDelete()
    var
        InteractionCommentLine: Record "Inter. Log Entry Comment Line";
        Attachment: Record Attachment;
        CampaignMgt: Codeunit "Campaign Target Group Mgt";
    begin
        InteractionCommentLine.SetRange("Entry No.", "Entry No.");
        InteractionCommentLine.DeleteAll();

        CampaignMgt.DeleteContfromTargetGr(Rec);
        if UniqueAttachment() then
            if Attachment.Get("Attachment No.") then
                Attachment.RemoveAttachment(false);
    end;

    var
        Text000: Label '%1 %2 is marked %3.\';
        Text001: Label 'Do you wish to remove the checkmark?';
        Text002: Label 'Do you wish to mark %1 %2 as %3?';
        Text003: Label 'It is not possible to view sales statements after they have been printed.';
        Text004: Label 'It is not possible to show cover sheets after they have been printed.';
        Text005: Label 'Do you wish to remove the checkmark from the selected %1 lines?';
        Text006: Label 'Do you wish to mark the selected %1 lines as %2?';
        Text009: Label 'Do you want to remove Attachment?';
        Text010: Label 'Do you want to remove unique Attachments for the selected lines?';
        Text011: Label 'Very Positive,Positive,Neutral,Negative,Very Negative';
        TitleFromLbl: Label '%1 - from %2', Comment = '%1 - document description, %2 - name';
        TitleByLbl: Label '%1 - by %2', Comment = '%1 - document description, %2 - name';
        OpenMessageQst: Label 'You are about to open an email message in Outlook Online. Email messages might contain harmful content. Use caution when interacting with the message. Do you want to continue?';

    procedure InsertRecord()
    var
        SequenceNoMgt: Codeunit "Sequence No. Mgt.";
    begin
        if not Insert() then begin
            SequenceNoMgt.RebaseSeqNo(DATABASE::"Interaction Log Entry");
            "Entry No." := SequenceNoMgt.GetNextSeqNo(DATABASE::"Interaction Log Entry");
            Insert();
        end;
    end;

    procedure AssignNewOpportunity()
    var
        Opportunity: Record Opportunity;
        Contact: Record Contact;
    begin
        TestField(Canceled, false);
        TestField("Opportunity No.", '');
        if "Contact No." <> '' then
            if Contact.Get("Contact No.") then
                Contact.CheckIfPrivacyBlockedGeneric();
        if "Contact Company No." <> '' then
            if Contact.Get("Contact Company No.") then
                Contact.CheckIfPrivacyBlockedGeneric();
        Opportunity.CreateFromInteractionLogEntry(Rec);
        "Opportunity No." := Opportunity."No.";
        Modify();
    end;

    procedure CanCreateOpportunity(): Boolean
    begin
        exit(not Canceled and ("Opportunity No." = ''));
    end;

    procedure CopyFromSegment(SegLine: Record "Segment Line")
    begin
        "Contact No." := SegLine."Contact No.";
        "Contact Company No." := SegLine."Contact Company No.";
        Date := SegLine.Date;
        Description := SegLine.Description;
        "Information Flow" := SegLine."Information Flow";
        "Initiated By" := SegLine."Initiated By";
        "Attachment No." := SegLine."Attachment No.";
        "Cost (LCY)" := SegLine."Cost (LCY)";
        "Duration (Min.)" := SegLine."Duration (Min.)";
        "User ID" := CopyStr(UserId(), 1, MaxStrLen("User ID"));
        "Interaction Group Code" := SegLine."Interaction Group Code";
        "Interaction Template Code" := SegLine."Interaction Template Code";
        "Interaction Language Code" := SegLine."Language Code";
        Subject := SegLine.Subject;
        "Campaign No." := SegLine."Campaign No.";
        "Campaign Entry No." := SegLine."Campaign Entry No.";
        "Campaign Response" := SegLine."Campaign Response";
        "Campaign Target" := SegLine."Campaign Target";
        "Segment No." := SegLine."Segment No.";
        Evaluation := SegLine.Evaluation;
        "Time of Interaction" := SegLine."Time of Interaction";
        "Attempt Failed" := SegLine."Attempt Failed";
        "To-do No." := SegLine."To-do No.";
        "Salesperson Code" := SegLine."Salesperson Code";
        "Correspondence Type" := SegLine."Correspondence Type";
        "Contact Alt. Address Code" := SegLine."Contact Alt. Address Code";
        "Document Type" := SegLine."Document Type";
        "Document No." := SegLine."Document No.";
        "Doc. No. Occurrence" := SegLine."Doc. No. Occurrence";
        "Version No." := SegLine."Version No.";
        "Send Word Docs. as Attmt." := SegLine."Send Word Doc. As Attmt.";
        "Contact Via" := SegLine."Contact Via";
        "Opportunity No." := SegLine."Opportunity No.";
        "Word Template Code" := SegLine."Word Template Code";

        OnAfterCopyFromSegment(Rec, SegLine);
    end;

    procedure CreateInteraction()
    var
        TempSegLine: Record "Segment Line" temporary;
        Contact: Record Contact;
    begin
        if "Contact No." <> '' then
            if Contact.Get("Contact No.") then
                Contact.CheckIfPrivacyBlockedGeneric();
        if "Contact Company No." <> '' then
            if Contact.Get("Contact Company No.") then
                Contact.CheckIfPrivacyBlockedGeneric();
        TempSegLine.CreateInteractionFromInteractLogEntry(Rec);
    end;

    procedure CreateTask()
    var
        TempTask: Record "To-do" temporary;
        Contact: Record Contact;
    begin
        if "Contact No." <> '' then
            if Contact.Get("Contact No.") then
                Contact.CheckIfPrivacyBlockedGeneric();
        if "Contact Company No." <> '' then
            if Contact.Get("Contact Company No.") then
                Contact.CheckIfPrivacyBlockedGeneric();
        TempTask.CreateTaskFromInteractLogEntry(Rec)
    end;

    procedure OpenAttachment()
    var
        Attachment: Record Attachment;
        SegLine: Record "Segment Line";
        WebRequestHelper: Codeunit "Web Request Helper";
        IStream: InStream;
        EmailMessageUrl: Text;
        IsHandled: Boolean;
    begin
        if "Attachment No." = 0 then
            exit;

        Attachment.Get("Attachment No.");

        IsHandled := false;
        OnBeforeOpenAttachment(Rec, IsHandled, Attachment);
        if IsHandled then
            exit;

        if Attachment."Storage Type" <> Attachment."Storage Type"::"Exchange Storage" then begin
            SegLine."Contact No." := "Contact No.";
            SegLine."Salesperson Code" := "Salesperson Code";
            SegLine."Contact Alt. Address Code" := "Contact Alt. Address Code";
            SegLine.Date := Date;
            SegLine."Campaign No." := "Campaign No.";
            SegLine."Segment No." := "Segment No.";
            SegLine."Line No." := "Entry No.";
            SegLine.Description := Description;
            SegLine.Subject := Subject;
            SegLine."Language Code" := "Interaction Language Code";
            OnOpenAttachmentOnBeforeShowAttachment(Rec, SegLine, Attachment);
            Attachment.ShowAttachment(SegLine, Format("Entry No.") + ' ' + Description);
        end else begin
            Attachment.CalcFields("Email Message Url");
            if Attachment."Email Message Url".HasValue() then begin
                Attachment."Email Message Url".CreateInStream(IStream);
                IStream.Read(EmailMessageUrl);
                if WebRequestHelper.IsHttpUrl(EmailMessageUrl) then begin
                    if Confirm(OpenMessageQst, true) then
                        HyperLink(EmailMessageUrl);
                    exit;
                end;
            end;
            Attachment.DisplayInOutlook();
        end;

        OnAfterOpenAttachment(Rec, Attachment, SegLine);
    end;

    procedure ToggleCanceledCheckmark()
    var
        ErrorTxt: Text[80];
        MasterCanceledCheckmark: Boolean;
        RemoveUniqueAttachment: Boolean;
    begin
        if Find('-') then
            if ConfirmToggleCanceledCheckmark(Count, ErrorTxt) then begin
                MasterCanceledCheckmark := not Canceled;
                if FindUniqueAttachment() and MasterCanceledCheckmark then
                    RemoveUniqueAttachment := Confirm(ErrorTxt, false);
                SetCurrentKey("Entry No.");
                if Find('-') then
                    repeat
                        SetCanceledCheckmark(MasterCanceledCheckmark, RemoveUniqueAttachment);
                    until Next() = 0;
            end;
    end;

    procedure SetCanceledCheckmark(CanceledCheckmark: Boolean; RemoveUniqueAttachment: Boolean)
    var
        CampaignEntry: Record "Campaign Entry";
        LoggedSegment: Record "Logged Segment";
        Attachment: Record Attachment;
        IsHandled: Boolean;
    begin
        OnBeforeSetCanceledCheckmark(Rec, CanceledCheckmark, RemoveUniqueAttachment, IsHandled);
        if IsHandled then
            exit;

        if Canceled and not CanceledCheckmark then begin
            if "Logged Segment Entry No." <> 0 then begin
                LoggedSegment.Get("Logged Segment Entry No.");
                LoggedSegment.TestField(Canceled, false);
            end;
            if "Campaign Entry No." <> 0 then begin
                CampaignEntry.Get("Campaign Entry No.");
                CampaignEntry.TestField(Canceled, false);
            end;
        end;

        if not Canceled and CanceledCheckmark then
            if UniqueAttachment() and RemoveUniqueAttachment then begin
                if Attachment.Get("Attachment No.") then
                    Attachment.RemoveAttachment(false);
                "Attachment No." := 0;
            end;

        Canceled := CanceledCheckmark;
        Modify();
    end;

    local procedure ConfirmToggleCanceledCheckmark(NumberOfSelectedLines: Integer; var ErrorTxt: Text[80]): Boolean
    begin
        if NumberOfSelectedLines = 1 then begin
            ErrorTxt := Text009;
            if Canceled then
                exit(Confirm(
                    Text000 +
                    Text001, true, TableCaption(), "Entry No.", FieldCaption(Canceled)));

            exit(Confirm(
                Text002, true, TableCaption(), "Entry No.", FieldCaption(Canceled)));
        end;
        ErrorTxt := Text010;
        if Canceled then
            exit(Confirm(
                Text005, true, TableCaption));

        exit(Confirm(
            Text006, true, TableCaption(), FieldCaption(Canceled)));
    end;

    procedure UniqueAttachment() IsUnique: Boolean
    var
        InteractLogEntry: Record "Interaction Log Entry";
    begin
        if "Attachment No." <> 0 then begin
            InteractLogEntry.SetCurrentKey("Attachment No.");
            InteractLogEntry.SetRange("Attachment No.", "Attachment No.");
            InteractLogEntry.SetFilter("Entry No.", '<>%1', "Entry No.");
            IsUnique := not InteractLogEntry.FindFirst();
        end;
    end;

    local procedure FindUniqueAttachment() IsUnique: Boolean
    begin
        if Find('-') then
            repeat
                IsUnique := UniqueAttachment();
            until (Next() = 0) or IsUnique
    end;

    procedure ShowDocument()
    var
        SalesHeader: Record "Sales Header";
        SalesHeaderArchive: Record "Sales Header Archive";
        SalesInvHeader: Record "Sales Invoice Header";
        SalesShptHeader: Record "Sales Shipment Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        IssuedReminderHeader: Record "Issued Reminder Header";
        PurchHeader: Record "Purchase Header";
        PurchHeaderArchive: Record "Purchase Header Archive";
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchRcptHeader: Record "Purch. Rcpt. Header";
        PurchCrMemoHeader: Record "Purch. Cr. Memo Hdr.";
        ServHeader: Record "Service Header";
        ReturnRcptHeader: Record "Return Receipt Header";
        IssuedFinChargeMemoHeader: Record "Issued Fin. Charge Memo Header";
        ReturnReceiptHeader: Record "Return Receipt Header";
        ReturnShipmentHeader: Record "Return Shipment Header";
        ServiceContractHeader: Record "Service Contract Header";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeShowDocument(Rec, IsHandled);
        if IsHandled then
            exit;

        case "Document Type" of
            "Document Type"::"Sales Qte.":
                if "Version No." <> 0 then begin
                    SalesHeaderArchive.Get(
                      SalesHeaderArchive."Document Type"::Quote, "Document No.",
                      "Doc. No. Occurrence", "Version No.");
                    SalesHeaderArchive.SetRange("Document Type", SalesHeaderArchive."Document Type"::Quote);
                    SalesHeaderArchive.SetRange("No.", "Document No.");
                    SalesHeaderArchive.SetRange("Doc. No. Occurrence", "Doc. No. Occurrence");
                    PAGE.Run(PAGE::"Sales Quote Archive", SalesHeaderArchive);
                end else begin
                    SalesHeader.Get(SalesHeader."Document Type"::Quote, "Document No.");
                    PAGE.Run(PAGE::"Sales Quote", SalesHeader);
                end;
            "Document Type"::"Sales Blnkt. Ord":
                if "Version No." <> 0 then begin
                    SalesHeaderArchive.Get(SalesHeaderArchive."Document Type"::"Blanket Order", "Document No.",
                      "Doc. No. Occurrence", "Version No.");
                    SalesHeaderArchive.SetRange("Document Type", SalesHeaderArchive."Document Type"::"Blanket Order");
                    SalesHeaderArchive.SetRange("No.", "Document No.");
                    SalesHeaderArchive.SetRange("Doc. No. Occurrence", "Doc. No. Occurrence");
                    PAGE.Run(PAGE::"Blanket Sales Order Archive", SalesHeaderArchive);
                end else begin
                    SalesHeader.Get(SalesHeader."Document Type"::"Blanket Order", "Document No.");
                    PAGE.Run(PAGE::"Blanket Sales Order", SalesHeader);
                end;
            "Document Type"::"Sales Ord. Cnfrmn.":
                if "Version No." <> 0 then begin
                    SalesHeaderArchive.Get(
                      SalesHeaderArchive."Document Type"::Order, "Document No.",
                      "Doc. No. Occurrence", "Version No.");
                    SalesHeaderArchive.SetRange("Document Type", SalesHeaderArchive."Document Type"::Order);
                    SalesHeaderArchive.SetRange("No.", "Document No.");
                    SalesHeaderArchive.SetRange("Doc. No. Occurrence", "Doc. No. Occurrence");
                    PAGE.Run(PAGE::"Sales Order Archive", SalesHeaderArchive);
                end else begin
                    SalesHeader.Get(SalesHeader."Document Type"::Order, "Document No.");
                    PAGE.Run(PAGE::"Sales Order", SalesHeader);
                end;
            "Document Type"::"Sales Draft Invoice":
                begin
                    SalesHeader.Get(SalesHeader."Document Type"::Invoice, "Document No.");
                    PAGE.Run(PAGE::"Sales Invoice", SalesHeader);
                end;
            "Document Type"::"Sales Inv.":
                begin
                    SalesInvHeader.Get("Document No.");
                    PAGE.Run(PAGE::"Posted Sales Invoice", SalesInvHeader);
                end;
            "Document Type"::"Sales Shpt. Note":
                begin
                    SalesShptHeader.Get("Document No.");
                    PAGE.Run(PAGE::"Posted Sales Shipment", SalesShptHeader);
                end;
            "Document Type"::"Sales Cr. Memo":
                begin
                    SalesCrMemoHeader.Get("Document No.");
                    PAGE.Run(PAGE::"Posted Sales Credit Memo", SalesCrMemoHeader);
                end;
            "Document Type"::"Sales Stmnt.":
                Error(Text003);
            "Document Type"::"Sales Rmdr.":
                begin
                    IssuedReminderHeader.Get("Document No.");
                    PAGE.Run(PAGE::"Issued Reminder", IssuedReminderHeader);
                end;
            "Document Type"::"Serv. Ord. Create":
                begin
                    ServHeader.Get(ServHeader."Document Type"::Order, "Document No.");
                    PAGE.Run(PAGE::"Service Order", ServHeader)
                end;
            "Document Type"::"Purch.Qte.":
                if "Version No." <> 0 then begin
                    PurchHeaderArchive.Get(
                      PurchHeaderArchive."Document Type"::Quote, "Document No.",
                      "Doc. No. Occurrence", "Version No.");
                    PurchHeaderArchive.SetRange("Document Type", PurchHeaderArchive."Document Type"::Quote);
                    PurchHeaderArchive.SetRange("No.", "Document No.");
                    PurchHeaderArchive.SetRange("Doc. No. Occurrence", "Doc. No. Occurrence");
                    PAGE.Run(PAGE::"Purchase Quote Archive", PurchHeaderArchive);
                end else begin
                    PurchHeader.Get(PurchHeader."Document Type"::Quote, "Document No.");
                    PAGE.Run(PAGE::"Purchase Quote", PurchHeader);
                end;
            "Document Type"::"Purch. Blnkt. Ord.":
                if "Version No." <> 0 then begin
                    PurchHeaderArchive.Get(
                      PurchHeaderArchive."Document Type"::"Blanket Order", "Document No.",
                      "Doc. No. Occurrence", "Version No.");
                    PurchHeaderArchive.SetRange("Document Type", PurchHeaderArchive."Document Type"::"Blanket Order");
                    PurchHeaderArchive.SetRange("No.", "Document No.");
                    PurchHeaderArchive.SetRange("Doc. No. Occurrence", "Doc. No. Occurrence");
                    PAGE.Run(PAGE::"Blanket Purchase Order Archive", PurchHeaderArchive);
                end else begin
                    PurchHeader.Get(PurchHeader."Document Type"::"Blanket Order", "Document No.");
                    PAGE.Run(PAGE::"Blanket Purchase Order", PurchHeader);
                end;
            "Document Type"::"Purch. Ord.":
                if "Version No." <> 0 then begin
                    PurchHeaderArchive.Get(
                      PurchHeaderArchive."Document Type"::Order, "Document No.",
                      "Doc. No. Occurrence", "Version No.");
                    PurchHeaderArchive.SetRange("Document Type", PurchHeaderArchive."Document Type"::Order);
                    PurchHeaderArchive.SetRange("No.", "Document No.");
                    PurchHeaderArchive.SetRange("Doc. No. Occurrence", "Doc. No. Occurrence");
                    PAGE.Run(PAGE::"Purchase Order Archive", PurchHeaderArchive);
                end else begin
                    PurchHeader.Get(PurchHeader."Document Type"::Order, "Document No.");
                    PAGE.Run(PAGE::"Purchase Order", PurchHeader);
                end;
            "Document Type"::"Purch. Inv.":
                begin
                    PurchInvHeader.Get("Document No.");
                    PAGE.Run(PAGE::"Posted Purchase Invoice", PurchInvHeader);
                end;
            "Document Type"::"Purch. Rcpt.":
                begin
                    PurchRcptHeader.Get("Document No.");
                    PAGE.Run(PAGE::"Posted Purchase Receipt", PurchRcptHeader);
                end;
            "Document Type"::"Purch. Cr. Memo":
                begin
                    PurchCrMemoHeader.Get("Document No.");
                    PAGE.Run(PAGE::"Posted Purchase Credit Memo", PurchCrMemoHeader);
                end;
            "Document Type"::"Cover Sheet":
                Error(Text004);
            "Document Type"::"Sales Return Order":
                if SalesHeader.Get(SalesHeader."Document Type"::"Return Order", "Document No.") then
                    PAGE.Run(PAGE::"Sales Return Order", SalesHeader)
                else begin
                    ReturnRcptHeader.SetRange("Return Order No.", "Document No.");
                    PAGE.Run(PAGE::"Posted Return Receipt", ReturnRcptHeader);
                end;
            "Document Type"::"Sales Finance Charge Memo":
                begin
                    IssuedFinChargeMemoHeader.Get("Document No.");
                    PAGE.Run(PAGE::"Issued Finance Charge Memo", IssuedFinChargeMemoHeader);
                end;
            "Document Type"::"Sales Return Receipt":
                begin
                    ReturnReceiptHeader.Get("Document No.");
                    PAGE.Run(PAGE::"Posted Return Receipt", ReturnReceiptHeader);
                end;
            "Document Type"::"Purch. Return Shipment":
                begin
                    ReturnShipmentHeader.Get("Document No.");
                    PAGE.Run(PAGE::"Posted Return Shipment", ReturnShipmentHeader);
                end;
            "Document Type"::"Purch. Return Ord. Cnfrmn.":
                if PurchHeader.Get(PurchHeader."Document Type"::"Return Order", "Document No.") then
                    PAGE.Run(PAGE::"Purchase Return Order", PurchHeader)
                else begin
                    ReturnShipmentHeader.SetRange("Return Order No.", "Document No.");
                    PAGE.Run(PAGE::"Posted Return Shipment", ReturnShipmentHeader);
                end;
            "Document Type"::"Service Contract":
                begin
                    ServiceContractHeader.Get(ServiceContractHeader."Contract Type"::Contract, "Document No.");
                    PAGE.Run(PAGE::"Service Contract", ServiceContractHeader);
                end;
            "Document Type"::"Service Contract Quote":
                begin
                    ServiceContractHeader.Get(ServiceContractHeader."Contract Type"::Quote, "Document No.");
                    PAGE.Run(PAGE::"Service Contract Quote", ServiceContractHeader);
                end;
            "Document Type"::"Service Quote":
                begin
                    ServHeader.Get(ServHeader."Document Type"::Quote, "Document No.");
                    PAGE.Run(PAGE::"Service Quote", ServHeader);
                end;
        end;

        OnAfterShowDocument(Rec);
    end;

    procedure EvaluateInteraction()
    var
        Selected: Integer;
    begin
        if Find('-') then begin
            Selected := DIALOG.StrMenu(Text011);
            if Selected <> 0 then
                repeat
                    Evaluation := "Interaction Evaluation".FromInteger(Selected);
                    Modify();
                until Next() = 0
        end;
    end;

    procedure ResumeInteraction()
    var
        TempSegLine: Record "Segment Line" temporary;
    begin
        TempSegLine.CopyFromInteractLogEntry(Rec);
        TempSegLine.Validate(Date, WorkDate());

        if TempSegLine."To-do No." <> '' then
            TempSegLine.SetRange("To-do No.", TempSegLine."To-do No.");

        if TempSegLine."Contact Company No." <> '' then
            TempSegLine.SetRange("Contact Company No.", TempSegLine."Contact Company No.");

        if TempSegLine."Contact No." <> '' then
            TempSegLine.SetRange("Contact No.", TempSegLine."Contact No.");

        if TempSegLine."Salesperson Code" <> '' then
            TempSegLine.SetRange("Salesperson Code", TempSegLine."Salesperson Code");

        if TempSegLine."Campaign No." <> '' then
            TempSegLine.SetRange("Campaign No.", TempSegLine."Campaign No.");

        if TempSegLine."Opportunity No." <> '' then
            TempSegLine.SetRange("Opportunity No.", TempSegLine."Opportunity No.");

        OnResumeInteractionOnBeforeStartWizard(Rec, TempSegLine);
        TempSegLine.StartWizard();
    end;

    procedure GetEntryTitle() EntryTitle: Text
    var
        InteractionTemplate: Record "Interaction Template";
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        User: Record User;
    begin
        if InteractionTemplate.Get("Interaction Template Code") then begin
            EntryTitle := InteractionTemplate.Description;
            case InteractionTemplate."Information Flow" of
                InteractionTemplate."Information Flow"::Outbound:
                    if ("Salesperson Code" <> '') and SalespersonPurchaser.Get("Salesperson Code") then
                        EntryTitle := StrSubstNo(TitleByLbl, InteractionTemplate.Description, SalespersonPurchaser.Name)
                    else begin
                        User.SetRange("User Name", "User ID");
                        if User.FindFirst() then
                            EntryTitle := StrSubstNo(TitleByLbl, InteractionTemplate.Description, User."Full Name");
                    end;
                InteractionTemplate."Information Flow"::Inbound:
                    begin
                        CalcFields("Contact Name");
                        EntryTitle := StrSubstNo(TitleFromLbl, InteractionTemplate.Description, "Contact Name");
                    end;
            end;
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyFromSegment(var InteractionLogEntry: Record "Interaction Log Entry"; SegmentLine: Record "Segment Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterShowDocument(var InteractionLogEntry: Record "Interaction Log Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOpenAttachment(var InteractionLogEntry: Record "Interaction Log Entry"; var IsHandled: Boolean; var Attachment: Record Attachment)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeShowDocument(var InteractionLogEntry: Record "Interaction Log Entry"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetCanceledCheckmark(var InteractionLogEntry: Record "Interaction Log Entry"; CanceledCheckmark: Boolean; RemoveUniqueAttachment: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterOpenAttachment(var InteractionLogEntry: Record "Interaction Log Entry"; Attachment: Record Attachment; var SegmentLine: Record "Segment Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnOpenAttachmentOnBeforeShowAttachment(var InteractionLogEntry: Record "Interaction Log Entry"; var SegmentLine: Record "Segment Line"; var Attachment: Record Attachment)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnResumeInteractionOnBeforeStartWizard(InteractionLogEntry: Record "Interaction Log Entry"; var SegmentLine: Record "Segment Line")
    begin
    end;
}

