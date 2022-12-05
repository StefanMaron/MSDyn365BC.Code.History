table 9657 "Custom Report Selection"
{
    Caption = 'Custom Report Selection';

    fields
    {
        field(1; "Source Type"; Integer)
        {
            Caption = 'Source Type';
        }
        field(2; "Source No."; Code[20])
        {
            Caption = 'Source No.';
            TableRelation = IF ("Source Type" = CONST(18)) Customer."No."
            ELSE
            IF ("Source Type" = CONST(23)) Vendor."No.";
        }
        field(3; Usage; Enum "Report Selection Usage")
        {
            Caption = 'Usage';
        }
        field(4; Sequence; Integer)
        {
            AutoIncrement = true;
            Caption = 'Sequence';
        }
        field(5; "Report ID"; Integer)
        {
            Caption = 'Report ID';
            TableRelation = AllObjWithCaption."Object ID" WHERE("Object Type" = CONST(Report));

            trigger OnValidate()
            begin
                CalcFields("Report Caption");
                if ("Report ID" = 0) or ("Report ID" <> xRec."Report ID") then begin
                    Validate("Custom Report Layout Code", '');
                    Validate("Email Body Layout Code", '');
                end;
            end;
        }
        field(6; "Report Caption"; Text[250])
        {
            CalcFormula = Lookup(AllObjWithCaption."Object Caption" WHERE("Object Type" = CONST(Report),
                                                                           "Object ID" = FIELD("Report ID")));
            Caption = 'Report Caption';
            Editable = false;
            FieldClass = FlowField;
        }
        field(7; "Custom Report Layout Code"; Code[20])
        {
            Caption = 'Custom Report Layout Code';
            TableRelation = "Custom Report Layout" WHERE(Code = FIELD("Custom Report Layout Code"));

            trigger OnValidate()
            begin
                CalcFields("Custom Report Description");
            end;
        }
        field(8; "Custom Report Description"; Text[250])
        {
            CalcFormula = Lookup("Custom Report Layout".Description WHERE(Code = FIELD("Custom Report Layout Code")));
            Caption = 'Custom Report Description';
            FieldClass = FlowField;
        }
        field(9; "Send To Email"; Text[200])
        {
            Caption = 'Send To Email';

            trigger OnValidate()
            var
                MailManagement: Codeunit "Mail Management";
            begin
                if "Send To Email" <> '' then begin
                    if "Use Email from Contact" then
                        Error(UseEmailFromContactErr);
                    MailManagement.CheckValidEmailAddresses("Send To Email");
                end else
                    ClearSeletedContactsFilter();
            end;
        }
        field(19; "Use for Email Attachment"; Boolean)
        {
            Caption = 'Use for Email Attachment';
            InitValue = true;

            trigger OnValidate()
            begin
                if not "Use for Email Body" then
                    Validate("Email Body Layout Code", '');
            end;
        }
        field(20; "Use for Email Body"; Boolean)
        {
            Caption = 'Use for Email Body';

            trigger OnValidate()
            begin
                if not "Use for Email Body" then
                    Validate("Email Body Layout Code", '');
            end;
        }
        field(21; "Email Body Layout Code"; Code[20])
        {
            Caption = 'Email Body Layout Code';
            TableRelation = "Custom Report Layout" WHERE(Code = FIELD("Email Body Layout Code"),
                                                          "Report ID" = FIELD("Report ID"));

            trigger OnValidate()
            begin
                if "Email Body Layout Code" <> '' then
                    TestField("Use for Email Body", true);
                CalcFields("Email Body Layout Description");
            end;
        }
        field(22; "Email Body Layout Description"; Text[250])
        {
            CalcFormula = Lookup("Custom Report Layout".Description WHERE(Code = FIELD("Email Body Layout Code")));
            Caption = 'Email Body Layout Description';
            Editable = false;
            FieldClass = FlowField;
        }
        field(23; "Use Email from Contact"; Boolean)
        {
            Caption = 'Use Email from Contacts';
        }
        field(24; "Selected Contacts Filter"; Blob)
        {
            Caption = 'Selected Contacts Filter';
        }
    }

    keys
    {
        key(Key1; "Source Type", "Source No.", Usage, Sequence)
        {
            Clustered = true;
        }
        key(Key2; "Report ID")
        {
        }
    }

    fieldgroups
    {
    }

    trigger OnInsert()
    begin
        TestField("Report ID");
        CheckEmailBodyUsage();
    end;

    trigger OnModify()
    begin
        TestField("Report ID");
        CheckEmailBodyUsage();
    end;

    var
        EmailBodyIsAlreadyDefinedErr: Label 'An email body is already defined for %1.', Comment = '%1 = Usage, for example Sales Invoice';
        CannotBeUsedAsAnEmailBodyErr: Label 'Report %1 uses the %2, which cannot be used as an email body.', Comment = '%1 = Report ID,%2 = Type';
        TargetEmailAddressErr: Label 'The target email address has not been specified on the document layout for %1, %2. //Choose the Document Layouts action on the customer or vendor card to specify the email address.', Comment = '%1 - Source Data RecordID, %2 - Usage';
        ExceededContactsNotificationTxt: Label 'Too many contacts were selected. Only %1 of %2 contact emails were processed. You can revise contact selection.', Comment = '%1 = number of contacts, %2 = number of contacts';
        UseEmailFromContactErr: Label 'You already use emails from contacts and cannot enter email addresses manually. Delete the value in the Send to Email field, and then enter another email address.';
        StartUseEmailFromContactTxt: Label 'Choose the Select Email from Contacts action if you want to view the list of contacts that will be used to send emails.';

    procedure InitUsage()
    begin
        Usage := xRec.Usage;
    end;

    procedure FilterReportUsage(NewSourceType: Integer; NewSourceNo: Code[20]; NewUsage: Option)
    begin
        Reset();
        SetRange("Source Type", NewSourceType);
        SetRange("Source No.", NewSourceNo);
        SetRange(Usage, NewUsage);
    end;

    procedure FilterEmailBodyUsage(NewSourceType: Integer; NewSourceNo: Code[20]; NewUsage: Option)
    begin
        FilterReportUsage(NewSourceType, NewSourceNo, NewUsage);
        SetRange("Use for Email Body", true);

        OnAfterFilterEmailBodyUsage(Rec, NewSourceType, NewSourceNo, NewUsage);
    end;

    local procedure CheckEmailBodyUsage()
    var
        CustomReportSelection: Record "Custom Report Selection";
        ReportLayoutSelection: Record "Report Layout Selection";
        ShowEmailBodyDefinedError: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckEmailBodyUsage(Rec, IsHandled);
        if IsHandled then
            exit;

        if "Use for Email Body" then begin
            CustomReportSelection.FilterEmailBodyUsage("Source Type", "Source No.", Usage.AsInteger());
            CustomReportSelection.SetFilter(Sequence, '<>%1', Sequence);
            ShowEmailBodyDefinedError := not CustomReportSelection.IsEmpty();
            OnCheckEmailBodyUsageOnAfterCalcShowEmailBodyDefinedError(Rec, CustomReportSelection, ShowEmailBodyDefinedError);
            if ShowEmailBodyDefinedError then
                Error(EmailBodyIsAlreadyDefinedErr, Usage);

            if "Email Body Layout Code" = '' then
                if ReportLayoutSelection.GetDefaultType("Report ID") =
                   ReportLayoutSelection.Type::"RDLC (built-in)"
                then
                    Error(CannotBeUsedAsAnEmailBodyErr, "Report ID", ReportLayoutSelection.Type);
        end;
    end;

    local procedure LookupCustomReportLayout(CurrentLayoutCode: Code[20]): Code[20]
    var
        CustomReportLayout: Record "Custom Report Layout";
    begin
        if CustomReportLayout.LookupLayoutOK("Report ID") then
            exit(CustomReportLayout.Code);

        exit(CurrentLayoutCode);
    end;

    procedure LookupCustomReportDescription()
    begin
        Validate("Custom Report Layout Code", LookupCustomReportLayout("Custom Report Layout Code"));
    end;

    procedure LookupEmailBodyDescription()
    begin
        Validate("Email Body Layout Code", LookupCustomReportLayout("Custom Report Layout Code"));
    end;

    [Scope('OnPrem')]
    procedure CheckEmailSendTo(DataRecRef: RecordRef)
    var
        ErrorMessageManagement: Codeunit "Error Message Management";
        ErrorMessage: Text;
    begin
        if GetSendToEmail(true) = '' then begin
            ErrorMessage := StrSubstNo(TargetEmailAddressErr, DataRecRef.RecordId, Usage);
            ErrorMessageManagement.LogError(Rec, ErrorMessage, '');
        end;
    end;

    procedure CopyFromReportSelections(var ReportSelections: Record "Report Selections"; SourceType: Integer; SourceNo: Code[20])
    var
        CustomReportSelection: Record "Custom Report Selection";
        SequenceNo: Integer;
    begin
        if ReportSelections.FindSet() then begin
            SequenceNo := GetSequenceNo();
            CustomReportSelection.SetRange("Source Type", SourceType);
            CustomReportSelection.SetRange("Source No.", SourceNo);
            repeat
                CustomReportSelection.SetRange(Usage, ReportSelections.Usage);
                CustomReportSelection.SetRange("Report ID", ReportSelections."Report ID");
                if CustomReportSelection.IsEmpty() then begin
                    Init();
                    Validate("Source Type", SourceType);
                    Validate("Source No.", SourceNo);
                    Validate(Usage, ReportSelections.Usage);
                    Validate(Sequence, SequenceNo);
                    Validate("Report ID", ReportSelections."Report ID");
                    Validate("Use for Email Body", ReportSelections."Use for Email Body");
                    Validate("Use for Email Attachment", ReportSelections."Use for Email Attachment");
                    Validate("Custom Report Layout Code", ReportSelections."Custom Report Layout Code");
                    if ReportSelections."Email Body Layout Type" = ReportSelections."Email Body Layout Type"::"Custom Report Layout" then
                        Validate("Email Body Layout Code", ReportSelections."Email Body Layout Code");
                    OnCopyFromReportSelectionsOnBeforeInsert(Rec, ReportSelections);
                    Insert();
                    SequenceNo += 1;
                end;
            until ReportSelections.Next() = 0;
        end;

        OnCopyFromReportSelections(Rec, ReportSelections);
    end;

    procedure GetSendToEmailFromContactsSelection(LinkType: Option; LinkNo: Code[20])
    var
        Contact: Record Contact;
        ContBusRel: Record "Contact Business Relation";
    begin
        ContBusRel.FindContactsByRelation(Contact, "Contact Business Relation Link to Table".FromInteger(LinkType), LinkNo);
        if IsCustomerVendorLinkType("Contact Business Relation Link to Table".FromInteger(LinkType)) then
            GetCustomerVendorAdditionalContacts(Contact, "Contact Business Relation Link to Table".FromInteger(LinkType), LinkNo);
        if Contact.FindSet() then
            if Contact.GetContactsSelectionFromContactList(true) then
                GetSendToEmailFromContacts(Contact);
    end;

    procedure GetSendToEmailFromContacts(var Contact: Record Contact)
    var
        ExceededContactsNotification: Notification;
        EmailList: Text;
        FieldLenghtExceeded: Boolean;
        MaxFieldLength: Integer;
        ProcessedContactsCount: Integer;
        ShowExceededContactsNotification: Boolean;
    begin
        "Send To Email" := '';
        if Contact.FindSet() then begin
            MaxFieldLength := MaxStrLen("Send To Email");
            repeat
                if Contact."E-Mail" <> '' then
                    if StrLen(EmailList + Contact."E-Mail") <= MaxFieldLength then begin
                        ProcessedContactsCount += 1;
                        EmailList += Contact."E-Mail";
                        if StrLen(EmailList) < MaxFieldLength then
                            EmailList += ';';
                    end else begin
                        FieldLenghtExceeded := true;
                        ShowExceededContactsNotification := FieldLenghtExceeded;
                    end;
            until (Contact.Next() = 0) or FieldLenghtExceeded;
        end;
        EmailList := DelChr(EmailList, '>', ';');
        "Send To Email" := CopyStr(EmailList, 1, MaxStrLen("Send To Email"));
        if "Send To Email" <> '' then
            FillSelectedContactsFilter(Contact.GetFilter("No."));
        OnGetSendToEmailFromContacts(Rec, Contact, ShowExceededContactsNotification);

        if ShowExceededContactsNotification then begin
            ExceededContactsNotification.Scope(NotificationScope::LocalScope);
            ExceededContactsNotification.Message(StrSubstNo(ExceededContactsNotificationTxt, ProcessedContactsCount, Contact.Count));
            ExceededContactsNotification.Send();
        end;
    end;

    procedure ShowSelectedContacts()
    var
        Contact: Record Contact;
    begin
        if "Use Email from Contact" then begin
            Contact.SetFilter("No.", GetSelectedContactsFilter());
            Contact.GetContactsSelectionFromContactList(false);
        end else
            Message(StartUseEmailFromContactTxt);
    end;

    local procedure ClearSeletedContactsFilter()
    begin
        CalcFields("Selected Contacts Filter");
        Clear("Selected Contacts Filter");
        "Use Email from Contact" := false;
    end;

    local procedure FillSelectedContactsFilter(SelectedContactsFilter: Text)
    var
        OStream: OutStream;
    begin
        if SelectedContactsFilter = '' then
            exit;
        if "Selected Contacts Filter".HasValue() then begin
            CalcFields("Selected Contacts Filter");
            Clear("Selected Contacts Filter");
        end;
        "Selected Contacts Filter".CreateOutStream(OStream);
        OStream.WriteText(SelectedContactsFilter);
        "Use Email from Contact" := true;
    end;

    local procedure GetSelectedContactsFilter() SelectedContactsFilter: Text
    var
        IStream: InStream;
    begin
        if not "Selected Contacts Filter".HasValue() then
            exit('');

        CalcFields("Selected Contacts Filter");
        "Selected Contacts Filter".CreateInStream(IStream);
        IStream.ReadText(SelectedContactsFilter);
        OnGetSelectedContactsFilter(SelectedContactsFilter);
    end;

    procedure GetSendToEmail(Update: Boolean) Result: Text[250]
    var
        Contact: Record Contact;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetSendToEmail(Update, Result, IsHandled);
        if IsHandled then
            exit(Result);

        if "Use Email from Contact" then begin
            Contact.SetFilter("No.", GetSelectedContactsFilter());
            FillSendToEmail(Contact);
            if Update then
                Modify();
        end;
        exit("Send To Email");
    end;

    local procedure FillSendToEmail(var Contact: Record Contact)
    var
        EmailList: Text;
        MaxFieldLength: Integer;
        FieldLenghtExceeded: Boolean;
    begin
        "Send To Email" := '';
        MaxFieldLength := MaxStrLen("Send To Email");
        if Contact.FindSet() then
            repeat
                if Contact."E-Mail" <> '' then
                    if StrLen(EmailList + Contact."E-Mail") <= MaxFieldLength then begin
                        EmailList += Contact."E-Mail";
                        if StrLen(EmailList) < MaxFieldLength then
                            EmailList += ';';
                    end else
                        FieldLenghtExceeded := true;
            until (Contact.Next() = 0) or FieldLenghtExceeded;
        EmailList := DelChr(EmailList, '>', ';');
        "Send To Email" := CopyStr(EmailList, 1, MaxStrLen("Send To Email"));
    end;

    procedure UpdateSendtoEmail(Update: Boolean)
    begin
        if FindSet() then
            repeat
                GetSendToEmail(Update);
            until Next() = 0;
    end;

    local procedure GetSequenceNo(): Integer
    var
        CustomReportSelection: Record "Custom Report Selection";
    begin
        CustomReportSelection.SetCurrentKey(Sequence);
        if CustomReportSelection.FindLast() then
            exit(CustomReportSelection.Sequence + 1);
        exit(1);
    end;

    local procedure IsCustomerVendorLinkType(LinkType: Enum "Contact Business Relation Link To Table"): Boolean
    begin
        exit((LinkType = LinkType::Customer) or (LinkType = LinkType::Vendor));
    end;

    local procedure GetCustomerVendorAdditionalContacts(var Contact: Record Contact; LinkType: Enum "Contact Business Relation Link To Table"; LinkNo: Code[20])
    var
        Customer: Record Customer;
        Vendor: Record Vendor;
        BillToPayToContact: Record Contact;
        ContactBusinessRelation: Record "Contact Business Relation";
        CVNo: Code[20];
    begin
        case LinkType of
            "Contact Business Relation Link To Table"::Customer:
                begin
                    Customer.Get(LinkNo);
                    if Customer.Get(Customer."Bill-to Customer No.") then
                        CVNo := Customer."No.";
                end;
            "Contact Business Relation Link To Table"::Vendor:
                begin
                    Vendor.Get(LinkNo);
                    if Vendor.Get(Vendor."Pay-to Vendor No.") then
                        CVNo := Vendor."No.";
                end;
        end;

        if ContactBusinessRelation.FindContactsByRelation(BillToPayToContact, LinkType, CVNo) then
            CombineContacts(Contact, BillToPayToContact);
    end;

    local procedure CombineContacts(var Contact: Record Contact; var BillToPayToContact: Record Contact)
    var
        SelectionFilterManagement: Codeunit SelectionFilterManagement;
        ContactNoFilter: Text;
    begin
        ContactNoFilter := SelectionFilterManagement.GetSelectionFilterForContact(Contact);
        if ContactNoFilter <> '' then
            ContactNoFilter += '|' + SelectionFilterManagement.GetSelectionFilterForContact(BillToPayToContact)
        else
            ContactNoFilter := SelectionFilterManagement.GetSelectionFilterForContact(BillToPayToContact);

        Contact.Reset();
        Contact.SetFilter("No.", ContactNoFilter);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFilterEmailBodyUsage(var CustomReportSelection: Record "Custom Report Selection"; NewSourceType: Integer; NewSourceNo: Code[20]; NewUsage: Option)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckEmailBodyUsage(var CustomReportSelection: Record "Custom Report Selection"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeGetSendToEmail(Update: Boolean; var Result: Text[250]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckEmailBodyUsageOnAfterCalcShowEmailBodyDefinedError(var Rec: Record "Custom Report Selection"; var CustomReportSelection: Record "Custom Report Selection"; var ShowEmailBodyDefinedError: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopyFromReportSelections(var CustomReportSelection: Record "Custom Report Selection"; var ReportSelections: Record "Report Selections")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopyFromReportSelectionsOnBeforeInsert(var CustomReportSelection: Record "Custom Report Selection"; ReportSelections: Record "Report Selections")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetSendToEmailFromContacts(var CustomReportSelection: Record "Custom Report Selection"; var Contact: Record Contact; var ShowExceededContactsNotification: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetSelectedContactsFilter(var SelectedContactsFilter: Text)
    begin
    end;
}

