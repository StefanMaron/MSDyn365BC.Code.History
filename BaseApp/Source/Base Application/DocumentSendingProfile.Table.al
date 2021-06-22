table 60 "Document Sending Profile"
{
    Caption = 'Document Sending Profile';
    LookupPageID = "Document Sending Profiles";

    fields
    {
        field(1; "Code"; Code[20])
        {
            Caption = 'Code';
            NotBlank = true;
        }
        field(2; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(10; Printer; Option)
        {
            Caption = 'Printer';
            OptionCaption = 'No,Yes (Prompt for Settings),Yes (Use Default Settings)';
            OptionMembers = No,"Yes (Prompt for Settings)","Yes (Use Default Settings)";
        }
        field(11; "E-Mail"; Option)
        {
            Caption = 'Email';
            OptionCaption = 'No,Yes (Prompt for Settings),Yes (Use Default Settings)';
            OptionMembers = No,"Yes (Prompt for Settings)","Yes (Use Default Settings)";
        }
        field(12; "E-Mail Attachment"; Option)
        {
            Caption = 'Email Attachment';
            OptionCaption = 'PDF,Electronic Document,PDF & Electronic Document';
            OptionMembers = PDF,"Electronic Document","PDF & Electronic Document";
        }
        field(13; "E-Mail Format"; Code[20])
        {
            Caption = 'Email Format';
            TableRelation = "Electronic Document Format".Code;
        }
        field(15; Disk; Option)
        {
            Caption = 'Disk';
            OptionCaption = 'No,PDF,Electronic Document,PDF & Electronic Document';
            OptionMembers = No,PDF,"Electronic Document","PDF & Electronic Document";
        }
        field(16; "Disk Format"; Code[20])
        {
            Caption = 'Disk Format';
            TableRelation = "Electronic Document Format".Code;
        }
        field(20; "Electronic Document"; Option)
        {
            Caption = 'Electronic Document';
            OptionCaption = 'No,Through Document Exchange Service';
            OptionMembers = No,"Through Document Exchange Service";
        }
        field(21; "Electronic Format"; Code[20])
        {
            Caption = 'Electronic Format';
            TableRelation = "Electronic Document Format".Code;
        }
        field(30; Default; Boolean)
        {
            Caption = 'Default';

            trigger OnValidate()
            var
                DocumentSendingProfile: Record "Document Sending Profile";
            begin
                if (xRec.Default = true) and (Default = false) then
                    Error(CannotRemoveDefaultRuleErr);

                DocumentSendingProfile.SetRange(Default, true);
                DocumentSendingProfile.ModifyAll(Default, false, false);
            end;
        }
        field(50; "Send To"; Option)
        {
            Caption = 'Send To';
            OptionCaption = 'Disk,Email,Print,Electronic Document';
            OptionMembers = Disk,Email,Print,"Electronic Document";
        }
        field(51; Usage; Option)
        {
            Caption = 'Usage';
            OptionCaption = 'Sales Invoice,Sales Credit Memo,,Service Invoice,Service Credit Memo,Job Quote';
            OptionMembers = "Sales Invoice","Sales Credit Memo",,"Service Invoice","Service Credit Memo","Job Quote";
        }
        field(52; "One Related Party Selected"; Boolean)
        {
            Caption = 'One Related Party Selected';
            InitValue = true;

            trigger OnValidate()
            begin
                if not "One Related Party Selected" then begin
                    "Electronic Document" := "Electronic Document"::No;
                    "Electronic Format" := '';
                end;
            end;
        }
    }

    keys
    {
        key(Key1; "Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    var
        Customer: Record Customer;
    begin
        if Default then
            Error(CannotDeleteDefaultRuleErr);

        Customer.SetRange("Document Sending Profile", Code);
        if Customer.FindFirst then begin
            if Confirm(UpdateAssCustomerQst, false, Code) then
                Customer.ModifyAll("Document Sending Profile", '')
            else
                Error(CannotDeleteErr);
        end;
    end;

    trigger OnInsert()
    var
        DocumentSendingProfile: Record "Document Sending Profile";
    begin
        DocumentSendingProfile.SetRange(Default, true);
        if not DocumentSendingProfile.FindFirst then
            Default := true;
    end;

    var
        DefaultCodeTxt: Label 'DEFAULT', Comment = 'Translate as we translate default term in local languages';
        DefaultDescriptionTxt: Label 'Default rule used if no other provided';
        RecordAsTextFormatterTxt: Label '%1 ; %2';
        FieldCaptionContentFormatterTxt: Label '%1 (%2)', Comment = '%1=Field Caption (e.g. Email), %2=Field Content (e.g. PDF) so for example ''Email (PDF)''';
        CannotDeleteDefaultRuleErr: Label 'You cannot delete the default rule. Assign other rule to be default first.';
        CannotRemoveDefaultRuleErr: Label 'There must be one default rule in the system. To remove the default property from this rule, assign default to another rule.';
        UpdateAssCustomerQst: Label 'If you delete document sending profile %1, it will also be deleted on customer cards that use the profile.\\Do you want to continue?';
        CannotDeleteErr: Label 'Cannot delete the document sending profile.';
        CannotSendMultipleSalesDocsErr: Label 'You can only send one electronic sales document at a time.';
        InvoicesTxt: Label 'Invoices';
        ShipmentsTxt: Label 'Shipments';
        CreditMemosTxt: Label 'Credit Memos';
        ReceiptsTxt: Label 'Receipts';
        JobQuotesTxt: Label 'Job Quotes';
        PurchaseOrdersTxt: Label 'Purchase Orders';
        ProfileSelectionQst: Label 'Confirm the first profile and use it for all selected documents.,Confirm the profile for each document.,Use the default profile for all selected documents without confimation.', Comment = 'Translation should contain comma separators between variants as ENU value does. No other commas should be there.';
        CustomerProfileSelectionInstrTxt: Label 'Customers on the selected documents might use different document sending profiles. Choose one of the following options: ';
        VendorProfileSelectionInstrTxt: Label 'Vendors on the selected documents might use different document sending profiles. Choose one of the following options: ';

    procedure GetDefaultForCustomer(CustomerNo: Code[20]; var DocumentSendingProfile: Record "Document Sending Profile")
    var
        Customer: Record Customer;
    begin
        if Customer.Get(CustomerNo) then
            if DocumentSendingProfile.Get(Customer."Document Sending Profile") then
                exit;

        GetDefault(DocumentSendingProfile);
    end;

    procedure GetDefaultForVendor(VendorNo: Code[20]; var DocumentSendingProfile: Record "Document Sending Profile")
    var
        Vendor: Record Vendor;
    begin
        if Vendor.Get(VendorNo) then
            if DocumentSendingProfile.Get(Vendor."Document Sending Profile") then
                exit;

        GetDefault(DocumentSendingProfile);
    end;

    procedure GetDefault(var DefaultDocumentSendingProfile: Record "Document Sending Profile")
    var
        DocumentSendingProfile: Record "Document Sending Profile";
    begin
        DocumentSendingProfile.SetRange(Default, true);
        if not DocumentSendingProfile.FindFirst then begin
            DocumentSendingProfile.Init();
            DocumentSendingProfile.Validate(Code, DefaultCodeTxt);
            DocumentSendingProfile.Validate(Description, DefaultDescriptionTxt);
            DocumentSendingProfile.Validate("E-Mail", "E-Mail"::"Yes (Prompt for Settings)");
            DocumentSendingProfile.Validate("E-Mail Attachment", "E-Mail Attachment"::PDF);
            DocumentSendingProfile.Validate(Default, true);
            DocumentSendingProfile.Insert(true);
        end;

        DefaultDocumentSendingProfile := DocumentSendingProfile;
    end;

    procedure GetRecordAsText(): Text
    var
        RecordAsText: Text;
    begin
        RecordAsText := '';

        if ("Electronic Document" <> "Electronic Document"::No) and ("Electronic Format" <> '') then
            RecordAsText := StrSubstNo(
                RecordAsTextFormatterTxt,
                StrSubstNo(FieldCaptionContentFormatterTxt, FieldCaption("Electronic Document"), "Electronic Document"), RecordAsText);

        if "E-Mail" <> "E-Mail"::No then
            RecordAsText := StrSubstNo(
                RecordAsTextFormatterTxt,
                StrSubstNo(FieldCaptionContentFormatterTxt, FieldCaption("E-Mail"), "E-Mail Attachment"), RecordAsText);
        if Printer <> Printer::No then
            RecordAsText := StrSubstNo(RecordAsTextFormatterTxt, FieldCaption(Printer), RecordAsText);

        if Disk <> Disk::No then
            RecordAsText := StrSubstNo(
                RecordAsTextFormatterTxt, StrSubstNo(FieldCaptionContentFormatterTxt, FieldCaption(Disk), Disk), RecordAsText);

        exit(RecordAsText);
    end;

    procedure WillUserBePrompted(): Boolean
    begin
        exit(
          (Printer = Printer::"Yes (Prompt for Settings)") or
          ("E-Mail" = "E-Mail"::"Yes (Prompt for Settings)"));
    end;

    procedure SetDocumentUsage(DocumentVariant: Variant)
    var
        ElectronicDocumentFormat: Record "Electronic Document Format";
        DocumentUsage: Option;
    begin
        ElectronicDocumentFormat.GetDocumentUsage(DocumentUsage, DocumentVariant);
        Validate(Usage, DocumentUsage);
    end;

    procedure VerifySelectedOptionsValid()
    begin
        if "One Related Party Selected" then
            exit;

        if "E-Mail Attachment" > "E-Mail Attachment"::PDF then
            Error(CannotSendMultipleSalesDocsErr);

        if "Electronic Document" > "Electronic Document"::No then
            Error(CannotSendMultipleSalesDocsErr);
    end;

    procedure LookupProfile(CustNo: Code[20]; Multiselection: Boolean; ShowDialog: Boolean): Boolean
    var
        DocumentSendingProfile: Record "Document Sending Profile";
        OfficeMgt: Codeunit "Office Management";
    begin
        if OfficeMgt.IsAvailable then begin
            GetOfficeAddinDefault(Rec, OfficeMgt.AttachAvailable);
            exit(true);
        end;

        GetDefaultForCustomer(CustNo, DocumentSendingProfile);
        if ShowDialog then
            exit(RunSelectSendingOptionsPage(DocumentSendingProfile.Code, Multiselection));

        Rec := DocumentSendingProfile;
        exit(true);
    end;

    procedure LookUpProfileVendor(VendorNo: Code[20]; Multiselection: Boolean; ShowDialog: Boolean): Boolean
    var
        DocumentSendingProfile: Record "Document Sending Profile";
        OfficeMgt: Codeunit "Office Management";
    begin
        if OfficeMgt.IsAvailable then begin
            GetOfficeAddinDefault(Rec, OfficeMgt.AttachAvailable);
            exit(true);
        end;

        DocumentSendingProfile.GetDefaultForVendor(VendorNo, DocumentSendingProfile);
        if ShowDialog then
            exit(RunSelectSendingOptionsPage(DocumentSendingProfile.Code, Multiselection));

        Rec := DocumentSendingProfile;
        exit(true);
    end;

    local procedure RunSelectSendingOptionsPage(DocumentSendingProfileCode: Code[20]; OneRelatedPartySelected: Boolean): Boolean
    var
        TempDocumentSendingProfile: Record "Document Sending Profile" temporary;
    begin
        TempDocumentSendingProfile.Init();
        TempDocumentSendingProfile.Code := DocumentSendingProfileCode;
        TempDocumentSendingProfile.Validate("One Related Party Selected", OneRelatedPartySelected);
        TempDocumentSendingProfile.Insert();

        Commit();
        if PAGE.RunModal(PAGE::"Select Sending Options", TempDocumentSendingProfile) = ACTION::LookupOK then begin
            Rec := TempDocumentSendingProfile;
            exit(true);
        end;

        exit(false);
    end;

    procedure SendCustomerRecords(ReportUsage: Integer; RecordVariant: Variant; DocName: Text[150]; CustomerNo: Code[20]; DocumentNo: Code[20]; CustomerFieldNo: Integer; DocumentFieldNo: Integer)
    var
        DocumentSendingProfile: Record "Document Sending Profile";
        RecRefSource: RecordRef;
        RecRefToSend: RecordRef;
        ProfileSelectionMethod: Option ConfirmDefault,ConfirmPerEach,UseDefault;
        SingleCustomerSelected: Boolean;
        ShowDialog: Boolean;
        Handled: Boolean;
    begin
        OnBeforeSendCustomerRecords(ReportUsage, RecordVariant, DocName, CustomerNo, DocumentNo, CustomerFieldNo, DocumentFieldNo, Handled);
        if Handled then
            exit;

        SingleCustomerSelected := IsSingleRecordSelected(RecordVariant, CustomerNo, CustomerFieldNo);

        if not SingleCustomerSelected then
            if not DocumentSendingProfile.ProfileSelectionMethodDialog(ProfileSelectionMethod, true) then
                exit;

        if SingleCustomerSelected or (ProfileSelectionMethod = ProfileSelectionMethod::ConfirmDefault) then begin
            if DocumentSendingProfile.LookupProfile(CustomerNo, true, true) then
                DocumentSendingProfile.Send(ReportUsage, RecordVariant, DocumentNo, CustomerNo, DocName, CustomerFieldNo, DocumentFieldNo);
        end else begin
            ShowDialog := ProfileSelectionMethod = ProfileSelectionMethod::ConfirmPerEach;
            RecRefSource.GetTable(RecordVariant);
            if RecRefSource.FindSet then
                repeat
                    RecRefToSend := RecRefSource.Duplicate;
                    RecRefToSend.SetRecFilter;
                    CustomerNo := RecRefToSend.Field(CustomerFieldNo).Value;
                    DocumentNo := RecRefToSend.Field(DocumentFieldNo).Value;
                    if DocumentSendingProfile.LookupProfile(CustomerNo, true, ShowDialog) then
                        DocumentSendingProfile.Send(ReportUsage, RecRefToSend, DocumentNo, CustomerNo, DocName, CustomerFieldNo, DocumentFieldNo);
                until RecRefSource.Next = 0;
        end;

        OnAfterSendCustomerRecords(ReportUsage, RecordVariant, DocName, CustomerNo, DocumentNo, CustomerFieldNo, DocumentFieldNo);
    end;

    procedure SendVendorRecords(ReportUsage: Integer; RecordVariant: Variant; DocName: Text[150]; VendorNo: Code[20]; DocumentNo: Code[20]; VendorFieldNo: Integer; DocumentFieldNo: Integer)
    var
        DocumentSendingProfile: Record "Document Sending Profile";
        RecRef: RecordRef;
        RecRef2: RecordRef;
        ProfileSelectionMethod: Option ConfirmDefault,ConfirmPerEach,UseDefault;
        SingleVendorSelected: Boolean;
        ShowDialog: Boolean;
        Handled: Boolean;
    begin
        OnBeforeSendVendorRecords(ReportUsage, RecordVariant, DocName, VendorNo, DocumentNo, VendorFieldNo, DocumentFieldNo, Handled);
        if Handled then
            exit;

        SingleVendorSelected := IsSingleRecordSelected(RecordVariant, VendorNo, VendorFieldNo);

        if not SingleVendorSelected then
            if not DocumentSendingProfile.ProfileSelectionMethodDialog(ProfileSelectionMethod, false) then
                exit;

        if SingleVendorSelected or (ProfileSelectionMethod = ProfileSelectionMethod::ConfirmDefault) then begin
            if DocumentSendingProfile.LookUpProfileVendor(VendorNo, true, true) then
                DocumentSendingProfile.SendVendor(ReportUsage, RecordVariant, DocumentNo, VendorNo, DocName, VendorFieldNo, DocumentFieldNo);
        end else begin
            ShowDialog := ProfileSelectionMethod = ProfileSelectionMethod::ConfirmPerEach;
            RecRef.GetTable(RecordVariant);
            if RecRef.FindSet then
                repeat
                    RecRef2 := RecRef.Duplicate;
                    RecRef2.SetRecFilter;
                    VendorNo := RecRef2.Field(VendorFieldNo).Value;
                    DocumentNo := RecRef2.Field(DocumentFieldNo).Value;
                    if DocumentSendingProfile.LookUpProfileVendor(VendorNo, true, ShowDialog) then
                        DocumentSendingProfile.SendVendor(ReportUsage, RecRef2, DocumentNo, VendorNo, DocName, VendorFieldNo, DocumentFieldNo);
                until RecRef.Next = 0;
        end;
    end;

    procedure Send(ReportUsage: Integer; RecordVariant: Variant; DocNo: Code[20]; ToCust: Code[20]; DocName: Text[150]; CustomerFieldNo: Integer; DocumentNoFieldNo: Integer)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSend(ReportUsage, RecordVariant, DocNo, ToCust, DocName, CustomerFieldNo, DocumentNoFieldNo, IsHandled);
        if IsHandled then
            exit;

        SendToVAN(RecordVariant);
        SendToPrinter(ReportUsage, RecordVariant, CustomerFieldNo);
        TrySendToEMailGroupedMultipleSelection(ReportUsage, RecordVariant, DocumentNoFieldNo, DocName, CustomerFieldNo);
        SendToDisk(ReportUsage, RecordVariant, DocNo, DocName, ToCust);

        OnAfterSend(ReportUsage, RecordVariant, DocNo, ToCust, DocName, CustomerFieldNo, DocumentNoFieldNo);
    end;

    procedure SendVendor(ReportUsage: Integer; RecordVariant: Variant; DocNo: Code[20]; ToVendor: Code[20]; DocName: Text[150]; VendorNoFieldNo: Integer; DocumentNoFieldNo: Integer)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSendVendor(ReportUsage, RecordVariant, DocNo, ToVendor, DocName, VendorNoFieldNo, DocumentNoFieldNo, IsHandled);
        if IsHandled then
            exit;

        SendToVAN(RecordVariant);
        SendToPrinterVendor(ReportUsage, RecordVariant, VendorNoFieldNo);
        TrySendToEMailGroupedMultipleSelectionVendor(ReportUsage, RecordVariant, DocumentNoFieldNo, DocName, VendorNoFieldNo);
        SendToDiskVendor(ReportUsage, RecordVariant, DocNo, DocName, ToVendor);

        OnAfterSendVendor(ReportUsage, RecordVariant, DocNo, ToVendor, DocName, VendorNoFieldNo, DocumentNoFieldNo);
    end;

    [Scope('OnPrem')]
    procedure TrySendToVAN(RecordVariant: Variant)
    begin
        "Electronic Document" := "Electronic Document"::"Through Document Exchange Service";
        SendToVAN(RecordVariant);
    end;

    procedure TrySendToPrinter(ReportUsage: Integer; RecordVariant: Variant; CustomerFieldNo: Integer; ShowDialog: Boolean)
    var
        Handled: Boolean;
    begin
        OnBeforeTrySendToPrinter(ReportUsage, RecordVariant, CustomerFieldNo, ShowDialog, Handled);
        if Handled then
            exit;

        if ShowDialog then
            Printer := Printer::"Yes (Prompt for Settings)"
        else
            Printer := Printer::"Yes (Use Default Settings)";

        SendToPrinter(ReportUsage, RecordVariant, CustomerFieldNo);
    end;

    procedure TrySendToPrinterVendor(ReportUsage: Integer; RecordVariant: Variant; VendorNoFieldNo: Integer; ShowDialog: Boolean)
    begin
        if ShowDialog then
            Printer := Printer::"Yes (Prompt for Settings)"
        else
            Printer := Printer::"Yes (Use Default Settings)";

        SendToPrinterVendor(ReportUsage, RecordVariant, VendorNoFieldNo);
    end;

    procedure TrySendToEMail(ReportUsage: Integer; RecordVariant: Variant; DocumentNoFieldNo: Integer; DocName: Text[150]; CustomerFieldNo: Integer; ShowDialog: Boolean)
    var
        Handled: Boolean;
    begin
        OnBeforeTrySendToEMail(ReportUsage, RecordVariant, DocumentNoFieldNo, DocName, CustomerFieldNo, ShowDialog, Handled);
        if Handled then
            exit;

        if ShowDialog then
            "E-Mail" := "E-Mail"::"Yes (Prompt for Settings)"
        else
            "E-Mail" := "E-Mail"::"Yes (Use Default Settings)";

        "E-Mail Attachment" := "E-Mail Attachment"::PDF;

        TrySendToEMailGroupedMultipleSelection(ReportUsage, RecordVariant, DocumentNoFieldNo, DocName, CustomerFieldNo);
    end;

    local procedure TrySendToEMailGroupedMultipleSelection(ReportUsage: Integer; RecordVariant: Variant; DocumentNoFieldNo: Integer; DocName: Text[150]; CustomerFieldNo: Integer)
    var
        TempCustomer: Record Customer temporary;
        RecRef: RecordRef;
        CustomerNoFieldRef: FieldRef;
        RecToSend: Variant;
    begin
        RecToSend := RecordVariant;
        RecRef.GetTable(RecordVariant);
        CustomerNoFieldRef := RecRef.Field(CustomerFieldNo);
        GetDisctinctCustomers(RecRef, CustomerFieldNo, TempCustomer);

        if TempCustomer.FindSet then
            repeat
                CustomerNoFieldRef.SetRange(TempCustomer."No.");
                RecRef.FindFirst;
                RecRef.SetTable(RecToSend);
                SendToEMail(
                  ReportUsage, RecToSend, GetMultipleDocumentsTo(RecRef, DocumentNoFieldNo),
                  GetMultipleDocumentsName(DocName, ReportUsage, RecRef), TempCustomer."No.");
            until TempCustomer.Next = 0;
    end;

    local procedure TrySendToEMailGroupedMultipleSelectionVendor(ReportUsage: Integer; RecordVariant: Variant; DocumentNoFieldNo: Integer; DocName: Text[150]; VendorFieldNo: Integer)
    var
        TempVendor: Record Vendor temporary;
        RecRef: RecordRef;
        VendorNoFieldRef: FieldRef;
        RecToSend: Variant;
    begin
        RecToSend := RecordVariant;
        RecRef.GetTable(RecordVariant);
        VendorNoFieldRef := RecRef.Field(VendorFieldNo);
        GetDistinctVendors(RecRef, VendorFieldNo, TempVendor);

        if TempVendor.FindSet then
            repeat
                VendorNoFieldRef.SetRange(TempVendor."No.");
                RecRef.FindFirst;
                RecRef.SetTable(RecToSend);
                SendToEmailVendor(
                  ReportUsage, RecToSend, GetMultipleDocumentsTo(RecRef, DocumentNoFieldNo),
                  GetMultipleDocumentsName(DocName, ReportUsage, RecRef), TempVendor."No.");
            until TempVendor.Next = 0;
    end;

    [Scope('OnPrem')]
    procedure TrySendToDisk(ReportUsage: Integer; RecordVariant: Variant; DocNo: Code[20]; DocName: Text[150]; ToCust: Code[20])
    begin
        Disk := Disk::PDF;
        SendToDisk(ReportUsage, RecordVariant, DocNo, DocName, ToCust);
    end;

    local procedure SendToVAN(RecordVariant: Variant)
    var
        ReportDistributionManagement: Codeunit "Report Distribution Management";
    begin
        if "Electronic Document" = "Electronic Document"::No then
            exit;

        ReportDistributionManagement.VANDocumentReport(RecordVariant, Rec);
    end;

    local procedure SendToPrinter(ReportUsage: Integer; RecordVariant: Variant; CustomerNoFieldNo: Integer)
    var
        ReportSelections: Record "Report Selections";
        ShowRequestForm: Boolean;
    begin
        if Printer = Printer::No then
            exit;

        ShowRequestForm := Printer = Printer::"Yes (Prompt for Settings)";
        ReportSelections.PrintWithGUIYesNo(ReportUsage, RecordVariant, ShowRequestForm, CustomerNoFieldNo);
    end;

    local procedure SendToPrinterVendor(ReportUsage: Integer; RecordVariant: Variant; VendorNoFieldNo: Integer)
    var
        ReportSelections: Record "Report Selections";
        ShowRequestForm: Boolean;
    begin
        if Printer = Printer::No then
            exit;

        ShowRequestForm := Printer = Printer::"Yes (Prompt for Settings)";
        ReportSelections.PrintWithGUIYesNoVendor(ReportUsage, RecordVariant, ShowRequestForm, VendorNoFieldNo);
    end;

    local procedure SendToEMail(ReportUsage: Integer; RecordVariant: Variant; DocNo: Code[20]; DocName: Text[150]; ToCust: Code[20])
    var
        ReportSelections: Record "Report Selections";
        ElectronicDocumentFormat: Record "Electronic Document Format";
        ReportDistributionManagement: Codeunit "Report Distribution Management";
        DocumentMailing: Codeunit "Document-Mailing";
        DataCompression: Codeunit "Data Compression";
        ShowDialog: Boolean;
        ClientFilePath: Text[250];
        ServerFilePath: Text[250];
        ZipPath: Text[250];
        ClientZipFileName: Text[250];
        ServerEmailBodyFilePath: Text[250];
        SendToEmailAddress: Text[250];
    begin
        if "E-Mail" = "E-Mail"::No then
            exit;

        ShowDialog := "E-Mail" = "E-Mail"::"Yes (Prompt for Settings)";

        case "E-Mail Attachment" of
            "E-Mail Attachment"::PDF:
                ReportSelections.SendEmailToCust(ReportUsage, RecordVariant, DocNo, DocName, ShowDialog, ToCust);
            "E-Mail Attachment"::"Electronic Document":
                begin
                    ReportSelections.GetEmailBody(ServerEmailBodyFilePath, ReportUsage, RecordVariant, ToCust, SendToEmailAddress);
                    ReportDistributionManagement.SendXmlEmailAttachment(
                      RecordVariant, "E-Mail Format", ServerEmailBodyFilePath, SendToEmailAddress);
                end;
            "E-Mail Attachment"::"PDF & Electronic Document":
                begin
                    ElectronicDocumentFormat.SendElectronically(ServerFilePath, ClientFilePath, RecordVariant, "E-Mail Format");
                    ReportDistributionManagement.CreateOrAppendZipFile(DataCompression, ServerFilePath, ClientFilePath, ClientZipFileName);
                    ReportSelections.SendToZip(ReportUsage, RecordVariant, DocNo, ToCust, DataCompression);
                    SaveZipArchiveToServerFile(DataCompression, ZipPath);

                    ReportSelections.GetEmailBody(ServerEmailBodyFilePath, ReportUsage, RecordVariant, ToCust, SendToEmailAddress);
                    DocumentMailing.EmailFile(
                      ZipPath, ClientZipFileName, ServerEmailBodyFilePath, DocNo, SendToEmailAddress, DocName,
                      not ShowDialog, ReportUsage);
                end;
        end;
    end;

    local procedure SendToEmailVendor(ReportUsage: Integer; RecordVariant: Variant; DocNo: Code[20]; DocName: Text[150]; ToVendor: Code[20])
    var
        ReportSelections: Record "Report Selections";
        ElectronicDocumentFormat: Record "Electronic Document Format";
        ReportDistributionManagement: Codeunit "Report Distribution Management";
        DocumentMailing: Codeunit "Document-Mailing";
        DataCompression: Codeunit "Data Compression";
        ShowDialog: Boolean;
        ClientFilePath: Text[250];
        ServerFilePath: Text[250];
        ZipPath: Text[250];
        ClientZipFileName: Text[250];
        ServerEmailBodyFilePath: Text[250];
        SendToEmailAddress: Text[250];
    begin
        if "E-Mail" = "E-Mail"::No then
            exit;

        ShowDialog := "E-Mail" = "E-Mail"::"Yes (Prompt for Settings)";

        case "E-Mail Attachment" of
            "E-Mail Attachment"::PDF:
                ReportSelections.SendEmailToVendor(ReportUsage, RecordVariant, DocNo, DocName, ShowDialog, ToVendor);
            "E-Mail Attachment"::"Electronic Document":
                begin
                    ReportSelections.GetEmailBodyVendor(ServerEmailBodyFilePath, ReportUsage, RecordVariant, ToVendor, SendToEmailAddress);
                    ReportDistributionManagement.SendXmlEmailAttachmentVendor(
                      RecordVariant, "E-Mail Format", ServerEmailBodyFilePath, SendToEmailAddress);
                end;
            "E-Mail Attachment"::"PDF & Electronic Document":
                begin
                    ElectronicDocumentFormat.SendElectronically(ServerFilePath, ClientFilePath, RecordVariant, "E-Mail Format");
                    ReportDistributionManagement.CreateOrAppendZipFile(DataCompression, ServerFilePath, ClientFilePath, ClientZipFileName);
                    ReportSelections.SendToZipVendor(ReportUsage, RecordVariant, DocNo, ToVendor, DataCompression);
                    SaveZipArchiveToServerFile(DataCompression, ZipPath);

                    ReportSelections.GetEmailBodyVendor(ServerEmailBodyFilePath, ReportUsage, RecordVariant, ToVendor, SendToEmailAddress);
                    DocumentMailing.EmailFile(
                      ZipPath, ClientZipFileName, ServerEmailBodyFilePath, DocNo, SendToEmailAddress, DocName,
                      not ShowDialog, ReportUsage);
                end;
        end;
    end;

    local procedure SendToDisk(ReportUsage: Integer; RecordVariant: Variant; DocNo: Code[20]; DocName: Text; ToCust: Code[20])
    var
        ReportSelections: Record "Report Selections";
        ElectronicDocumentFormat: Record "Electronic Document Format";
        ReportDistributionManagement: Codeunit "Report Distribution Management";
        DataCompression: Codeunit "Data Compression";
        ServerFilePath: Text[250];
        ClientFilePath: Text[250];
        ZipPath: Text[250];
        ClientZipFileName: Text[250];
        IsHandled: Boolean;
    begin
        if Disk = Disk::No then
            exit;

        OnBeforeSendToDisk(ReportUsage, RecordVariant, DocNo, DocName, ToCust, IsHandled);
        if IsHandled then
            exit;

        case Disk of
            Disk::PDF:
                ReportSelections.SendToDisk(ReportUsage, RecordVariant, DocNo, DocName, ToCust);
            Disk::"Electronic Document":
                begin
                    ElectronicDocumentFormat.SendElectronically(ServerFilePath, ClientFilePath, RecordVariant, "Disk Format");
                    ReportDistributionManagement.SaveFileOnClient(ServerFilePath, ClientFilePath);
                end;
            Disk::"PDF & Electronic Document":
                begin
                    ElectronicDocumentFormat.SendElectronically(ServerFilePath, ClientFilePath, RecordVariant, "Disk Format");
                    ReportDistributionManagement.CreateOrAppendZipFile(DataCompression, ServerFilePath, ClientFilePath, ClientZipFileName);
                    ReportSelections.SendToZip(ReportUsage, RecordVariant, DocNo, ToCust, DataCompression);
                    SaveZipArchiveToServerFile(DataCompression, ZipPath);

                    ReportDistributionManagement.SaveFileOnClient(ZipPath, ClientZipFileName);
                end;
        end;
    end;

    local procedure SendToDiskVendor(ReportUsage: Integer; RecordVariant: Variant; DocNo: Code[20]; DocName: Text; ToVendor: Code[20])
    var
        ReportSelections: Record "Report Selections";
        ElectronicDocumentFormat: Record "Electronic Document Format";
        ReportDistributionManagement: Codeunit "Report Distribution Management";
        DataCompression: Codeunit "Data Compression";
        ServerFilePath: Text[250];
        ClientFilePath: Text[250];
        ZipPath: Text[250];
        ClientZipFileName: Text[250];
    begin
        if Disk = Disk::No then
            exit;

        case Disk of
            Disk::PDF:
                ReportSelections.SendToDiskVendor(ReportUsage, RecordVariant, DocNo, DocName, ToVendor);
            Disk::"Electronic Document":
                begin
                    ElectronicDocumentFormat.SendElectronically(ServerFilePath, ClientFilePath, RecordVariant, "Disk Format");
                    ReportDistributionManagement.SaveFileOnClient(ServerFilePath, ClientFilePath);
                end;
            Disk::"PDF & Electronic Document":
                begin
                    ElectronicDocumentFormat.SendElectronically(ServerFilePath, ClientFilePath, RecordVariant, "Disk Format");
                    ReportDistributionManagement.CreateOrAppendZipFile(DataCompression, ServerFilePath, ClientFilePath, ClientZipFileName);
                    ReportSelections.SendToZipVendor(ReportUsage, RecordVariant, DocNo, ToVendor, DataCompression);
                    SaveZipArchiveToServerFile(DataCompression, ZipPath);

                    ReportDistributionManagement.SaveFileOnClient(ZipPath, ClientZipFileName);
                end;
        end;
    end;

    procedure GetOfficeAddinDefault(var TempDocumentSendingProfile: Record "Document Sending Profile" temporary; CanAttach: Boolean)
    begin
        with TempDocumentSendingProfile do begin
            Init;
            Code := DefaultCodeTxt;
            Description := DefaultDescriptionTxt;
            if CanAttach then
                "E-Mail" := "E-Mail"::"Yes (Use Default Settings)"
            else
                "E-Mail" := "E-Mail"::"Yes (Prompt for Settings)";
            "E-Mail Attachment" := "E-Mail Attachment"::PDF;
            Default := false;
        end;
    end;

    local procedure GetMultipleDocumentsName(DocName: Text[150]; ReportUsage: Integer; RecRef: RecordRef): Text[150]
    var
        ReportSelections: Record "Report Selections";
    begin
        if RecRef.Count > 1 then
            case ReportUsage of
                ReportSelections.Usage::"S.Invoice":
                    exit(InvoicesTxt);
                ReportSelections.Usage::"S.Shipment":
                    exit(ShipmentsTxt);
                ReportSelections.Usage::"S.Cr.Memo":
                    exit(CreditMemosTxt);
                ReportSelections.Usage::"S.Ret.Rcpt.":
                    exit(ReceiptsTxt);
                ReportSelections.Usage::JQ:
                    exit(JobQuotesTxt);
                ReportSelections.Usage::"P.Order":
                    exit(PurchaseOrdersTxt);
            end;

        exit(DocName);
    end;

    local procedure GetMultipleDocumentsTo(RecRef: RecordRef; DocumentNoFieldNo: Integer): Code[20]
    var
        DocumentNoFieldRef: FieldRef;
    begin
        if RecRef.Count > 1 then
            exit('');

        DocumentNoFieldRef := RecRef.Field(DocumentNoFieldNo);
        exit(DocumentNoFieldRef.Value);
    end;

    local procedure GetDisctinctCustomers(RecRef: RecordRef; CustomerFieldNo: Integer; var TempCustomer: Record Customer temporary)
    var
        FieldRef: FieldRef;
        CustomerNo: Code[20];
    begin
        if RecRef.FindSet then
            repeat
                FieldRef := RecRef.Field(CustomerFieldNo);
                CustomerNo := FieldRef.Value;
                if not TempCustomer.Get(CustomerNo) then begin
                    TempCustomer."No." := CustomerNo;
                    TempCustomer.Insert();
                end;
            until RecRef.Next = 0;
    end;

    local procedure GetDistinctVendors(RecRef: RecordRef; VendorFieldNo: Integer; var TempVendor: Record Vendor temporary)
    var
        FieldRef: FieldRef;
        VendorNo: Code[20];
    begin
        if RecRef.FindSet then
            repeat
                FieldRef := RecRef.Field(VendorFieldNo);
                VendorNo := FieldRef.Value;
                if not TempVendor.Get(VendorNo) then begin
                    TempVendor."No." := VendorNo;
                    TempVendor.Insert();
                end;
            until RecRef.Next = 0;
    end;

    procedure ProfileSelectionMethodDialog(var ProfileSelectionMethod: Option ConfirmDefault,ConfirmPerEach,UseDefault; IsCustomer: Boolean): Boolean
    var
        ProfileSelectionInstruction: Text;
    begin
        if IsCustomer then
            ProfileSelectionInstruction := CustomerProfileSelectionInstrTxt
        else
            ProfileSelectionInstruction := VendorProfileSelectionInstrTxt;

        case StrMenu(ProfileSelectionQst, 3, ProfileSelectionInstruction) of
            0:
                exit(false);
            1:
                ProfileSelectionMethod := ProfileSelectionMethod::ConfirmDefault;
            2:
                ProfileSelectionMethod := ProfileSelectionMethod::ConfirmPerEach;
            3:
                ProfileSelectionMethod := ProfileSelectionMethod::UseDefault;
        end;
        exit(true);
    end;

    local procedure IsSingleRecordSelected(RecordVariant: Variant; CVNo: Code[20]; CVFieldNo: Integer): Boolean
    var
        RecRef: RecordRef;
        FieldRef: FieldRef;
    begin
        RecRef.GetTable(RecordVariant);
        if not RecRef.FindSet then
            exit(false);

        if RecRef.Next = 0 then
            exit(true);

        FieldRef := RecRef.Field(CVFieldNo);
        FieldRef.SetFilter('<>%1', CVNo);
        exit(RecRef.IsEmpty);
    end;

    procedure CheckElectronicSendingEnabled()
    var
        DocExchServiceMgt: Codeunit "Doc. Exch. Service Mgt.";
    begin
        if "Electronic Document" <> "Electronic Document"::No then
            if not HasThirdPartyDocExchService then
                DocExchServiceMgt.CheckServiceEnabled;
    end;

    local procedure HasThirdPartyDocExchService() ExchServiceEnabled: Boolean
    begin
        OnCheckElectronicSendingEnabled(ExchServiceEnabled);
    end;

    local procedure SaveZipArchiveToServerFile(var DataCompression: Codeunit "Data Compression"; var ZipPath: Text)
    var
        FileManagement: Codeunit "File Management";
        ZipFile: File;
        ZipFileOutStream: OutStream;
    begin
        ZipPath := CopyStr(FileManagement.ServerTempFileName('zip'), 1, 250);
        ZipFile.Create(ZipPath);
        ZipFile.CreateOutStream(ZipFileOutStream);
        DataCompression.SaveZipArchive(ZipFileOutStream);
        DataCompression.CloseZipArchive;
        ZipFile.Close;
    end;

    [IntegrationEvent(TRUE, false)]
    local procedure OnAfterSend(ReportUsage: Integer; RecordVariant: Variant; DocNo: Code[20]; ToCust: Code[20]; DocName: Text[150]; CustomerFieldNo: Integer; DocumentNoFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSendCustomerRecords(ReportUsage: Integer; RecordVariant: Variant; DocName: Text[150]; CustomerNo: Code[20]; DocumentNo: Code[20]; CustomerFieldNo: Integer; DocumentFieldNo: Integer);
    begin
    end;

    [IntegrationEvent(TRUE, false)]
    local procedure OnAfterSendVendor(ReportUsage: Integer; RecordVariant: Variant; DocNo: Code[20]; ToVendor: Code[20]; DocName: Text[150]; VendorNoFieldNo: Integer; DocumentNoFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(TRUE, false)]
    local procedure OnBeforeSend(ReportUsage: Integer; RecordVariant: Variant; DocNo: Code[20]; ToCust: Code[20]; DocName: Text[150]; CustomerFieldNo: Integer; DocumentNoFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSendCustomerRecords(ReportUsage: Integer; RecordVariant: Variant; DocName: Text[150]; CustomerNo: Code[20]; DocumentNo: Code[20]; CustomerFieldNo: Integer; DocumentFieldNo: Integer; var Handled: Boolean)
    begin
    end;

    [IntegrationEvent(TRUE, false)]
    local procedure OnBeforeSendVendor(ReportUsage: Integer; RecordVariant: Variant; DocNo: Code[20]; ToVendor: Code[20]; DocName: Text[150]; VendorNoFieldNo: Integer; DocumentNoFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSendVendorRecords(ReportUsage: Integer; RecordVariant: Variant; DocName: Text[150]; VendorNo: Code[20]; DocumentNo: Code[20]; VendorFieldNo: Integer; DocumentFieldNo: Integer; var Handled: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeSendToDisk(ReportUsage: Integer; RecordVariant: Variant; DocNo: Code[20]; DocName: Text; ToCust: Code[20]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTrySendToPrinter(ReportUsage: Integer; RecordVariant: Variant; CustomerFieldNo: Integer; ShowDialog: Boolean; var Handled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTrySendToEMail(ReportUsage: Integer; RecordVariant: Variant; DocumentNoFieldNo: Integer; DocName: Text[150]; CustomerFieldNo: Integer; ShowDialog: Boolean; var Handled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckElectronicSendingEnabled(var ExchServiceEnabled: Boolean)
    begin
    end;
}

