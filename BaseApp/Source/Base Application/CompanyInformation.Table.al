table 79 "Company Information"
{
    Caption = 'Company Information';

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            Caption = 'Primary Key';
        }
        field(2; Name; Text[100])
        {
            Caption = 'Name';
        }
        field(3; "Name 2"; Text[50])
        {
            Caption = 'Name 2';
        }
        field(4; Address; Text[100])
        {
            Caption = 'Address';
        }
        field(5; "Address 2"; Text[50])
        {
            Caption = 'Address 2';
        }
        field(6; City; Text[30])
        {
            Caption = 'City';
            TableRelation = IF ("Country/Region Code" = CONST('')) "Post Code".City
            ELSE
            IF ("Country/Region Code" = FILTER(<> '')) "Post Code".City WHERE("Country/Region Code" = FIELD("Country/Region Code"));
            //This property is currently not supported
            //TestTableRelation = false;
            ValidateTableRelation = false;

            trigger OnLookup()
            begin
                PostCode.LookupPostCode(City, "Post Code", County, "Country/Region Code");
            end;

            trigger OnValidate()
            begin
                PostCode.ValidateCity(City, "Post Code", County, "Country/Region Code", (CurrFieldNo <> 0) and GuiAllowed);
            end;
        }
        field(7; "Phone No."; Text[30])
        {
            Caption = 'Phone No.';
            ExtendedDatatype = PhoneNo;
        }
        field(8; "Phone No. 2"; Text[30])
        {
            Caption = 'Phone No. 2';
            ExtendedDatatype = PhoneNo;
        }
        field(9; "Telex No."; Text[30])
        {
            Caption = 'Telex No.';
        }
        field(10; "Fax No."; Text[30])
        {
            Caption = 'Fax No.';
        }
        field(11; "Giro No."; Text[20])
        {
            Caption = 'Giro No.';
        }
        field(12; "Bank Name"; Text[100])
        {
            Caption = 'Bank Name';
        }
        field(13; "Bank Branch No."; Text[20])
        {
            Caption = 'Bank Branch No.';
        }
        field(14; "Bank Account No."; Text[30])
        {
            Caption = 'Bank Account No.';
        }
        field(15; "Payment Routing No."; Text[20])
        {
            Caption = 'Payment Routing No.';
        }
        field(17; "Customs Permit No."; Text[10])
        {
            Caption = 'Customs Permit No.';
        }
        field(18; "Customs Permit Date"; Date)
        {
            Caption = 'Customs Permit Date';
        }
        field(19; "VAT Registration No."; Text[20])
        {
            Caption = 'VAT Registration No.';

            trigger OnValidate()
            var
                VATRegNoFormat: Record "VAT Registration No. Format";
                VATRegistrationLog: Record "VAT Registration Log";
                VATRegNoSrvConfig: Record "VAT Reg. No. Srv Config";
                VATRegistrationLogMgt: Codeunit "VAT Registration Log Mgt.";
                ResultRecordRef: RecordRef;
            begin
                "VAT Registration No." := UpperCase("VAT Registration No.");
                if "VAT Registration No." = xRec."VAT Registration No." then
                    exit;
                if not VATRegNoFormat.Test("VAT Registration No.", "Country/Region Code", '', DATABASE::"Company Information") then
                    exit;
                if "Country/Region Code" = '' then
                    exit;
                if VATRegNoSrvConfig.VATRegNoSrvIsEnabled then begin
                    VATRegistrationLogMgt.ValidateVATRegNoWithVIES(ResultRecordRef, Rec, "Primary Key",
                      VATRegistrationLog."Account Type"::"Company Information", "Country/Region Code");
                    ResultRecordRef.SetTable(Rec);
                end;
            end;
        }
        field(20; "Registration No."; Text[20])
        {
            Caption = 'Registration No.';
        }
        field(21; "Telex Answer Back"; Text[20])
        {
            Caption = 'Telex Answer Back';
        }
        field(22; "Ship-to Name"; Text[100])
        {
            Caption = 'Ship-to Name';
        }
        field(23; "Ship-to Name 2"; Text[50])
        {
            Caption = 'Ship-to Name 2';
        }
        field(24; "Ship-to Address"; Text[100])
        {
            Caption = 'Ship-to Address';
        }
        field(25; "Ship-to Address 2"; Text[50])
        {
            Caption = 'Ship-to Address 2';
        }
        field(26; "Ship-to City"; Text[30])
        {
            Caption = 'Ship-to City';
            TableRelation = IF ("Ship-to Country/Region Code" = CONST('')) "Post Code".City
            ELSE
            IF ("Ship-to Country/Region Code" = FILTER(<> '')) "Post Code".City WHERE("Country/Region Code" = FIELD("Ship-to Country/Region Code"));
            //This property is currently not supported
            //TestTableRelation = false;
            ValidateTableRelation = false;

            trigger OnLookup()
            begin
                PostCode.LookupPostCode("Ship-to City", "Ship-to Post Code", "Ship-to County", "Ship-to Country/Region Code");
            end;

            trigger OnValidate()
            begin
                PostCode.ValidateCity(
                  "Ship-to City", "Ship-to Post Code", "Ship-to County", "Ship-to Country/Region Code", (CurrFieldNo <> 0) and GuiAllowed);
            end;
        }
        field(27; "Ship-to Contact"; Text[100])
        {
            Caption = 'Ship-to Contact';
        }
        field(28; "Location Code"; Code[10])
        {
            Caption = 'Location Code';
            TableRelation = Location WHERE("Use As In-Transit" = CONST(false));
        }
        field(29; Picture; BLOB)
        {
            Caption = 'Picture';
            SubType = Bitmap;

            trigger OnValidate()
            begin
                PictureUpdated := true;
            end;
        }
        field(30; "Post Code"; Code[20])
        {
            Caption = 'Post Code';
            TableRelation = IF ("Country/Region Code" = CONST('')) "Post Code".Code
            ELSE
            IF ("Country/Region Code" = FILTER(<> '')) "Post Code".Code WHERE("Country/Region Code" = FIELD("Country/Region Code"));
            //This property is currently not supported
            //TestTableRelation = false;
            ValidateTableRelation = false;

            trigger OnLookup()
            begin
                PostCode.LookupPostCode(City, "Post Code", County, "Country/Region Code");
            end;

            trigger OnValidate()
            begin
                PostCode.ValidatePostCode(City, "Post Code", County, "Country/Region Code", (CurrFieldNo <> 0) and GuiAllowed);
            end;
        }
        field(31; County; Text[30])
        {
            CaptionClass = '5,1,' + "Country/Region Code";
            Caption = 'County';
        }
        field(32; "Ship-to Post Code"; Code[20])
        {
            Caption = 'Ship-to Post Code';
            TableRelation = IF ("Ship-to Country/Region Code" = CONST('')) "Post Code".Code
            ELSE
            IF ("Ship-to Country/Region Code" = FILTER(<> '')) "Post Code".Code WHERE("Country/Region Code" = FIELD("Ship-to Country/Region Code"));
            //This property is currently not supported
            //TestTableRelation = false;
            ValidateTableRelation = false;

            trigger OnLookup()
            begin
                PostCode.LookupPostCode("Ship-to City", "Ship-to Post Code", "Ship-to County", "Ship-to Country/Region Code");
            end;

            trigger OnValidate()
            begin
                PostCode.ValidatePostCode(
                  "Ship-to City", "Ship-to Post Code", "Ship-to County", "Ship-to Country/Region Code", (CurrFieldNo <> 0) and GuiAllowed);
            end;
        }
        field(33; "Ship-to County"; Text[30])
        {
            CaptionClass = '5,1,' + "Ship-to Country/Region Code";
            Caption = 'Ship-to County';
        }
        field(34; "E-Mail"; Text[80])
        {
            Caption = 'Email';
            ExtendedDatatype = EMail;

            trigger OnValidate()
            var
                MailManagement: Codeunit "Mail Management";
            begin
                MailManagement.ValidateEmailAddressField("E-Mail");
            end;
        }
        field(35; "Home Page"; Text[80])
        {
            Caption = 'Home Page';
            ExtendedDatatype = URL;
        }
        field(36; "Country/Region Code"; Code[10])
        {
            Caption = 'Country/Region Code';
            TableRelation = "Country/Region";

            trigger OnValidate()
            begin
                PostCode.CheckClearPostCodeCityCounty(City, "Post Code", County, "Country/Region Code", xRec."Country/Region Code");
            end;
        }
        field(37; "Ship-to Country/Region Code"; Code[10])
        {
            Caption = 'Ship-to Country/Region Code';
            TableRelation = "Country/Region";
        }
        field(38; IBAN; Code[50])
        {
            Caption = 'IBAN';

            trigger OnValidate()
            begin
                CheckIBAN(IBAN);
            end;
        }
        field(39; "SWIFT Code"; Code[20])
        {
            Caption = 'SWIFT Code';
            TableRelation = "SWIFT Code";
            ValidateTableRelation = false;
        }
        field(40; "Industrial Classification"; Text[30])
        {
            Caption = 'Industrial Classification';
        }
        field(41; "IC Partner Code"; Code[20])
        {
            AccessByPermission = TableData "IC G/L Account" = R;
            Caption = 'IC Partner Code';
        }
        field(42; "IC Inbox Type"; Option)
        {
            AccessByPermission = TableData "IC G/L Account" = R;
            Caption = 'IC Inbox Type';
            InitValue = Database;
            OptionCaption = 'File Location,Database';
            OptionMembers = "File Location",Database;

            trigger OnValidate()
            begin
                if "IC Inbox Type" = "IC Inbox Type"::Database then
                    "IC Inbox Details" := '';
            end;
        }
        field(43; "IC Inbox Details"; Text[250])
        {
            AccessByPermission = TableData "IC G/L Account" = R;
            Caption = 'IC Inbox Details';

            trigger OnLookup()
            var
                FileMgt: Codeunit "File Management";
                FileName: Text;
                FileName2: Text;
                Path: Text;
            begin
                TestField("IC Partner Code");
                case "IC Inbox Type" of
                    "IC Inbox Type"::"File Location":
                        begin
                            if "IC Inbox Details" = '' then
                                FileName := StrSubstNo('%1.xml', "IC Partner Code")
                            else
                                FileName := "IC Inbox Details" + StrSubstNo('\%1.xml', "IC Partner Code");

                            FileName2 := FileMgt.SaveFileDialog(Text001, FileName, '');
                            if FileName <> FileName2 then begin
                                Path := FileMgt.GetDirectoryName(FileName2);
                                if Path <> '' then
                                    "IC Inbox Details" := CopyStr(Path, 1, 250);
                            end;
                        end;
                end;
            end;
        }
        field(44; "Auto. Send Transactions"; Boolean)
        {
            AccessByPermission = TableData "IC G/L Account" = R;
            Caption = 'Auto. Send Transactions';
        }
        field(46; "System Indicator"; Option)
        {
            Caption = 'System Indicator';
            OptionCaption = 'None,Custom';
            OptionMembers = "None","Custom";
        }
        field(47; "Custom System Indicator Text"; Text[250])
        {
            Caption = 'Custom System Indicator Text';
        }
        field(48; "System Indicator Style"; Option)
        {
            Caption = 'System Indicator Style';
            OptionCaption = 'Standard,Accent1,Accent2,Accent3,Accent4,Accent5,Accent6,Accent7,Accent8,Accent9';
            OptionMembers = Standard,Accent1,Accent2,Accent3,Accent4,Accent5,Accent6,Accent7,Accent8,Accent9;
        }
        field(50; "Allow Blank Payment Info."; Boolean)
        {
            Caption = 'Allow Blank Payment Info.';
        }
        field(51; "Contact Person"; Text[50])
        {
            Caption = 'Contact Person';
        }
        field(90; GLN; Code[13])
        {
            Caption = 'GLN';
            Numeric = true;

            trigger OnValidate()
            var
                GLNCalculator: Codeunit "GLN Calculator";
            begin
                if GLN <> '' then
                    if not GLNCalculator.IsValidCheckDigit13(GLN) then
                        Error(GLNCheckDigitErr, FieldCaption(GLN));
            end;
        }
        field(96; "Picture - Last Mod. Date Time"; DateTime)
        {
            Caption = 'Picture - Last Mod. Date Time';
            Editable = false;
        }
        field(98; "Last Modified Date Time"; DateTime)
        {
            Caption = 'Last Modified Date Time';
            Editable = false;
        }
        field(99; "Created DateTime"; DateTime)
        {
            Caption = 'Created DateTime';
            Editable = false;
        }
        field(100; "Demo Company"; Boolean)
        {
            Caption = 'Demo Company';
            Editable = false;
        }
        field(200; "Alternative Language Code"; Code[10])
        {
            Caption = 'Alternative Language Code';
            TableRelation = Language;
        }
        field(300; "Brand Color Value"; Code[10])
        {
            Caption = 'Brand Color Value';

            trigger OnValidate()
            var
                O365BrandColor: Record "O365 Brand Color";
            begin
                O365BrandColor.FindColor(O365BrandColor, "Brand Color Value");
                Validate("Brand Color Code", O365BrandColor.Code);
            end;
        }
        field(301; "Brand Color Code"; Code[20])
        {
            Caption = 'Brand Color Code';
            TableRelation = "O365 Brand Color";

            trigger OnValidate()
            begin
                SetBrandColorValue;
            end;
        }
        field(5700; "Responsibility Center"; Code[10])
        {
            Caption = 'Responsibility Center';
            TableRelation = "Responsibility Center".Code;
            ValidateTableRelation = true;
        }
        field(5791; "Check-Avail. Period Calc."; DateFormula)
        {
            AccessByPermission = TableData Item = R;
            Caption = 'Check-Avail. Period Calc.';
        }
        field(5792; "Check-Avail. Time Bucket"; Option)
        {
            AccessByPermission = TableData Item = R;
            Caption = 'Check-Avail. Time Bucket';
            OptionCaption = 'Day,Week,Month,Quarter,Year';
            OptionMembers = Day,Week,Month,Quarter,Year;
        }
        field(7600; "Base Calendar Code"; Code[10])
        {
            Caption = 'Base Calendar Code';
            TableRelation = "Base Calendar";
        }
        field(7601; "Cal. Convergence Time Frame"; DateFormula)
        {
            AccessByPermission = TableData "Base Calendar" = R;
            Caption = 'Cal. Convergence Time Frame';
            InitValue = '1Y';
        }
        field(7602; "Show Chart On RoleCenter"; Boolean)
        {
            Caption = 'Show Chart On RoleCenter';
            ObsoleteState = Pending;
            ObsoleteReason = 'Only the Help and Chart Wrapper pages used this. The page has been changed to assume that this field is always set.';
        }
        field(7603; "Sync with O365 Bus. profile"; Boolean)
        {
            Caption = 'Sync with O365 Bus. profile';

            trigger OnValidate()
            var
                GraphIntBusinessProfile: Codeunit "Graph Int - Business Profile";
            begin
                if "Sync with O365 Bus. profile" then
                    if IsSyncEnabledForOtherCompany then
                        Error(SyncAlreadyEnabledErr);

                if "Sync with O365 Bus. profile" then
                    CODEUNIT.Run(CODEUNIT::"Graph Data Setup")
                else
                    GraphIntBusinessProfile.UpdateCompanyBusinessProfileId('');
            end;
        }
        field(8000; Id; Guid)
        {
            Caption = 'Id';
            ObsoleteState = Pending;
            ObsoleteReason = 'This functionality will be replaced by the systemID field';
        }
    }

    keys
    {
        key(Key1; "Primary Key")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnInsert()
    begin
        "Last Modified Date Time" := CurrentDateTime;
        if PictureUpdated then
            "Picture - Last Mod. Date Time" := "Last Modified Date Time";
    end;

    trigger OnModify()
    begin
        "Last Modified Date Time" := CurrentDateTime;
        if PictureUpdated then
            "Picture - Last Mod. Date Time" := "Last Modified Date Time";
    end;

    var
        PostCode: Record "Post Code";
        NotValidIBANErr: Label 'The number %1 that you entered may not be a valid International Bank Account Number (IBAN). Do you want to continue?', Comment = '%1 - an actual IBAN';
        Text001: Label 'File Location for IC files';
        Text002: Label 'Before you can use Online Map, you must fill in the Online Map Setup window.\See Setting Up Online Map in Help.';
        NoPaymentInfoQst: Label 'No payment information is provided in %1. Do you want to update it now?', Comment = '%1 = Company Information';
        NoPaymentInfoMsg: Label 'No payment information is provided in %1. Review the report.';
        GLNCheckDigitErr: Label 'The %1 is not valid.';
        DevBetaModeTxt: Label 'DEV_BETA', Locked = true;
        SyncAlreadyEnabledErr: Label 'Office 365 Business profile synchronization is already enabled for another company in the system.';
        ContactUsFullTxt: Label 'Questions? Contact us at %1 or %2.', Comment = '%1 = phone number, %2 = email';
        ContactUsShortTxt: Label 'Questions? Contact us at %1.', Comment = '%1 = phone number or email';
        PictureUpdated: Boolean;
        AlTelemetryCategoryTxt: Label 'AL CompanyInfo', Locked = true;
        EmptyCountryRegionErr: Label 'Country/Region code is not set, falling back to application default: %1.', Locked = true;

    procedure CheckIBAN(IBANCode: Code[100])
    var
        OriginalIBANCode: Code[100];
        Modulus97: Integer;
        I: Integer;
    begin
        if IBANCode = '' then
            exit;
        OriginalIBANCode := IBANCode;
        IBANCode := DelChr(IBANCode);
        Modulus97 := 97;
        if (StrLen(IBANCode) <= 5) or (StrLen(IBANCode) > 34) then
            IBANError(OriginalIBANCode);
        ConvertIBAN(IBANCode);
        while StrLen(IBANCode) > 6 do
            IBANCode := CalcModulus(CopyStr(IBANCode, 1, 6), Modulus97) + CopyStr(IBANCode, 7);
        Evaluate(I, IBANCode);
        if (I mod Modulus97) <> 1 then
            IBANError(OriginalIBANCode);
    end;

    local procedure ConvertIBAN(var IBANCode: Code[100])
    var
        I: Integer;
    begin
        IBANCode := CopyStr(IBANCode, 5) + CopyStr(IBANCode, 1, 4);
        I := 0;
        while I < StrLen(IBANCode) do begin
            I := I + 1;
            if ConvertLetter(IBANCode, CopyStr(IBANCode, I, 1), I) then
                I := 0;
        end;
    end;

    local procedure CalcModulus(Number: Code[10]; Modulus97: Integer): Code[10]
    var
        I: Integer;
    begin
        Evaluate(I, Number);
        I := I mod Modulus97;
        if I = 0 then
            exit('');
        exit(Format(I));
    end;

    local procedure ConvertLetter(var IBANCode: Code[100]; Letter: Code[1]; LetterPlace: Integer): Boolean
    var
        Letter2: Code[2];
    begin
        if (Letter >= 'A') and (Letter <= 'Z') then begin
            case Letter of
                'A':
                    Letter2 := '10';
                'B':
                    Letter2 := '11';
                'C':
                    Letter2 := '12';
                'D':
                    Letter2 := '13';
                'E':
                    Letter2 := '14';
                'F':
                    Letter2 := '15';
                'G':
                    Letter2 := '16';
                'H':
                    Letter2 := '17';
                'I':
                    Letter2 := '18';
                'J':
                    Letter2 := '19';
                'K':
                    Letter2 := '20';
                'L':
                    Letter2 := '21';
                'M':
                    Letter2 := '22';
                'N':
                    Letter2 := '23';
                'O':
                    Letter2 := '24';
                'P':
                    Letter2 := '25';
                'Q':
                    Letter2 := '26';
                'R':
                    Letter2 := '27';
                'S':
                    Letter2 := '28';
                'T':
                    Letter2 := '29';
                'U':
                    Letter2 := '30';
                'V':
                    Letter2 := '31';
                'W':
                    Letter2 := '32';
                'X':
                    Letter2 := '33';
                'Y':
                    Letter2 := '34';
                'Z':
                    Letter2 := '35';
            end;
            if LetterPlace = 1 then
                IBANCode := Letter2 + CopyStr(IBANCode, 2)
            else begin
                if LetterPlace = StrLen(IBANCode) then
                    IBANCode := CopyStr(IBANCode, 1, LetterPlace - 1) + Letter2
                else
                    IBANCode :=
                      CopyStr(IBANCode, 1, LetterPlace - 1) + Letter2 + CopyStr(IBANCode, LetterPlace + 1);
            end;
            exit(true);
        end;
        if (Letter >= '0') and (Letter <= '9') then
            exit(false);

        IBANError(IBANCode);
    end;

    local procedure IBANError(WrongIBAN: Text)
    var
        ConfirmManagement: Codeunit "Confirm Management";
    begin
        if not ConfirmManagement.GetResponseOrDefault(StrSubstNo(NotValidIBANErr, WrongIBAN), true) then
            Error('');
    end;

    procedure DisplayMap()
    var
        MapPoint: Record "Online Map Setup";
        MapMgt: Codeunit "Online Map Management";
    begin
        if MapPoint.FindFirst then
            MapMgt.MakeSelection(DATABASE::"Company Information", GetPosition)
        else
            Message(Text002);
    end;

    local procedure IsPaymentInfoAvailble(): Boolean
    begin
        exit(
          (("Giro No." + IBAN + "Bank Name" + "Bank Branch No." + "Bank Account No." + "SWIFT Code") <> '') or
          "Allow Blank Payment Info.");
    end;

    procedure GetRegistrationNumber(): Text
    begin
        exit("Registration No.");
    end;

    procedure GetRegistrationNumberLbl(): Text
    begin
        exit(FieldCaption("Registration No."));
    end;

    procedure GetVATRegistrationNumber(): Text
    begin
        exit("VAT Registration No.");
    end;

    procedure GetVATRegistrationNumberLbl(): Text
    begin
        if Name = '' then // Is the record loaded?
            Get;
        if "VAT Registration No." = '' then
            exit('');
        exit(FieldCaption("VAT Registration No."));
    end;

    procedure GetLegalOffice(): Text
    begin
        exit('');
    end;

    procedure GetLegalOfficeLbl(): Text
    begin
        exit('');
    end;

    procedure GetCustomGiro(): Text
    begin
        exit('');
    end;

    procedure GetCustomGiroLbl(): Text
    begin
        exit('');
    end;

    procedure VerifyAndSetPaymentInfo()
    var
        ConfirmManagement: Codeunit "Confirm Management";
        CompanyInformationPage: Page "Company Information";
    begin
        Get;
        if IsPaymentInfoAvailble then
            exit;
        if ConfirmManagement.GetResponseOrDefault(StrSubstNo(NoPaymentInfoQst, TableCaption), true) then begin
            CompanyInformationPage.SetRecord(Rec);
            CompanyInformationPage.Editable(true);
            if CompanyInformationPage.RunModal = ACTION::OK then
                CompanyInformationPage.GetRecord(Rec);
        end;
        if not IsPaymentInfoAvailble then
            Message(NoPaymentInfoMsg, TableCaption);
    end;

    procedure GetSystemIndicator(var Text: Text[250]; var Style: Option Standard,Accent1,Accent2,Accent3,Accent4,Accent5,Accent6,Accent7,Accent8,Accent9)
    begin
        Style := "System Indicator Style";
        case "System Indicator" of
            "System Indicator"::None:
                Text := '';
            "System Indicator"::"Custom":
                Text := "Custom System Indicator Text";
        end;
        OnAfterGetSystemIndicator(Text, Style)
    end;

    local procedure GetDatabaseIndicatorText(IncludeCompany: Boolean): Text[250]
    var
        ActiveSession: Record "Active Session";
        Text: Text[1024];
    begin
        ActiveSession.SetRange("Server Instance ID", ServiceInstanceId);
        ActiveSession.SetRange("Session ID", SessionId);
        ActiveSession.FindFirst;
        Text := ActiveSession."Database Name" + ' - ' + ActiveSession."Server Computer Name";
        if IncludeCompany then
            Text := CompanyName + ' - ' + Text;
        if StrLen(Text) > 250 then
            exit(CopyStr(Text, 1, 247) + '...');
        exit(Text)
    end;

    procedure GetCountryRegionCode(CountryRegionCode: Code[10]): Code[10]
    begin
        case CountryRegionCode of
            '', "Country/Region Code":
                exit("Country/Region Code");
            else
                exit(CountryRegionCode);
        end;
    end;

    procedure GetCompanyCountryRegionCode(): Code[10]
    var
        MediaResourcesMgt: Codeunit "Media Resources Mgt.";
        CountryRegionCode: Code[10];
    begin
        if "Country/Region Code" <> '' then
            exit("Country/Region Code");

        CountryRegionCode := UpperCase(MediaResourcesMgt.ReadTextFromMediaResource('ApplicationCountry'));

        SendTraceTag(
          '00007HP',
          AlTelemetryCategoryTxt,
          VERBOSITY::Normal,
          StrSubstNo(EmptyCountryRegionErr, CountryRegionCode),
          DATACLASSIFICATION::SystemMetadata);

        exit(CountryRegionCode);
    end;

    procedure GetDevBetaModeTxt(): Text[250]
    begin
        exit(DevBetaModeTxt);
    end;

    procedure GetContactUsText(): Text
    begin
        if ("Phone No." <> '') and ("E-Mail" <> '') then
            exit(StrSubstNo(ContactUsFullTxt, "Phone No.", "E-Mail"));

        if "Phone No." <> '' then
            exit(StrSubstNo(ContactUsShortTxt, "Phone No."));

        if "E-Mail" <> '' then
            exit(StrSubstNo(ContactUsShortTxt, "E-Mail"));

        exit('');
    end;

    procedure IsSyncEnabledForOtherCompany() SyncEnabled: Boolean
    var
        CompanyInformation: Record "Company Information";
        Company: Record Company;
    begin
        Company.SetFilter(Name, '<>%1', CompanyName);
        if Company.FindSet then begin
            repeat
                CompanyInformation.ChangeCompany(Company.Name);
                if CompanyInformation.Get then
                    SyncEnabled := CompanyInformation."Sync with O365 Bus. profile";
            until (Company.Next = 0) or SyncEnabled;
        end;
    end;

    local procedure SetBrandColorValue()
    var
        O365BrandColor: Record "O365 Brand Color";
    begin
        if "Brand Color Code" <> '' then begin
            O365BrandColor.Get("Brand Color Code");
            "Brand Color Value" := O365BrandColor."Color Value";
        end else
            "Brand Color Value" := '';
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetSystemIndicator(var Text: Text[250]; var Style: Option Standard,Accent1,Accent2,Accent3,Accent4,Accent5,Accent6,Accent7,Accent8,Accent9)
    begin
    end;

    procedure SetPictureFromBlob(TempBlob: Codeunit "Temp Blob")
    var
        RecordRef: RecordRef;
    begin
        RecordRef.GetTable(Rec);
        TempBlob.ToRecordRef(RecordRef, FieldNo(Picture));
        RecordRef.SetTable(Rec);
    end;
}

