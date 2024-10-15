﻿namespace Microsoft.Foundation.Company;

using Microsoft.Bank.Setup;
using Microsoft.EServices.OnlineMap;
using Microsoft.Finance.VAT.Registration;
using Microsoft.Foundation.Address;
using Microsoft.Foundation.Calendar;
using Microsoft.Foundation.Enums;
using Microsoft.Intercompany.GLAccount;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Location;
using Microsoft.Utilities;
using System.Email;
using Microsoft.HumanResources.Employee;
using System.Globalization;
using System.Utilities;

table 79 "Company Information"
{
    Caption = 'Company Information';
    InherentEntitlements = X;
    InherentPermissions = X;

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
            TableRelation = if ("Country/Region Code" = const('')) "Post Code".City
            else
            if ("Country/Region Code" = filter(<> '')) "Post Code".City where("Country/Region Code" = field("Country/Region Code"));
            ValidateTableRelation = false;

            trigger OnLookup()
            begin
                PostCode.LookupPostCode(City, "Post Code", County, "Country/Region Code");
            end;

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateCity(Rec, IsHandled);
                if not IsHandled then
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
                if VATRegNoSrvConfig.VATRegNoSrvIsEnabled() then begin
                    VATRegistrationLogMgt.ValidateVATRegNoWithVIES(
                        ResultRecordRef, Rec, "Primary Key",
                        VATRegistrationLog."Account Type"::"Company Information".AsInteger(), "Country/Region Code");
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
            TableRelation = if ("Ship-to Country/Region Code" = const('')) "Post Code".City
            else
            if ("Ship-to Country/Region Code" = filter(<> '')) "Post Code".City where("Country/Region Code" = field("Ship-to Country/Region Code"));
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
            TableRelation = Location where("Use As In-Transit" = const(false));
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
            TableRelation = if ("Country/Region Code" = const('')) "Post Code".Code
            else
            if ("Country/Region Code" = filter(<> '')) "Post Code".Code where("Country/Region Code" = field("Country/Region Code"));
            ValidateTableRelation = false;

            trigger OnLookup()
            begin
                PostCode.LookupPostCode(City, "Post Code", County, "Country/Region Code");
            end;

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidatePostCode(Rec, IsHandled);
                if not IsHandled then
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
            TableRelation = if ("Ship-to Country/Region Code" = const('')) "Post Code".Code
            else
            if ("Ship-to Country/Region Code" = filter(<> '')) "Post Code".Code where("Country/Region Code" = field("Ship-to Country/Region Code"));
            ValidateTableRelation = false;

            trigger OnLookup()
            begin
                PostCode.LookupPostCode("Ship-to City", "Ship-to Post Code", "Ship-to County", "Ship-to Country/Region Code");
            end;

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnbeforeValidateShipToPostCode(Rec, IsHandled);
                if not IsHandled then
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
            ObsoleteReason = 'Replaced by the same field from "IC Setup" table.';
            ObsoleteState = Removed;
            ObsoleteTag = '23.0';
        }
        field(42; "IC Inbox Type"; Option)
        {
            AccessByPermission = TableData "IC G/L Account" = R;
            Caption = 'IC Inbox Type';
            InitValue = Database;
            OptionCaption = 'File Location,Database';
            OptionMembers = "File Location",Database;
            ObsoleteReason = 'Replaced by the same field from "IC Setup" table.';
            ObsoleteState = Removed;
            ObsoleteTag = '23.0';
        }
        field(43; "IC Inbox Details"; Text[250])
        {
            AccessByPermission = TableData "IC G/L Account" = R;
            Caption = 'IC Inbox Details';
            ObsoleteReason = 'Replaced by the same field from "IC Setup" table.';
            ObsoleteState = Removed;
            ObsoleteTag = '23.0';
        }
        field(44; "Auto. Send Transactions"; Boolean)
        {
            AccessByPermission = TableData "IC G/L Account" = R;
            Caption = 'Auto. Send Transactions';
            ObsoleteReason = 'Replaced by the same field from "IC Setup" table.';
            ObsoleteState = Removed;
            ObsoleteTag = '23.0';
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
        field(92; "EORI Number"; Text[40])
        {
            Caption = 'EORI Number';
        }
        field(95; "Use GLN in Electronic Document"; Boolean)
        {
            Caption = 'Use GLN in Electronic Documents';
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
                SetBrandColorValue();
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
        field(5792; "Check-Avail. Time Bucket"; Enum "Analysis Period Type")
        {
            AccessByPermission = TableData Item = R;
            Caption = 'Check-Avail. Time Bucket';
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
            ObsoleteState = Removed;
            ObsoleteReason = 'Only the Help and Chart Wrapper pages used this. The page has been changed to assume that this field is always set.';
            ObsoleteTag = '18.0';
        }
        field(7603; "Sync with O365 Bus. profile"; Boolean)
        {
            Caption = 'Sync with O365 Bus. profile';
            ObsoleteState = Removed;
            ObsoleteReason = 'The field will be removed. The API that this field was used for was discontinued.';
            ObsoleteTag = '20.0';
        }
        field(8000; Id; Guid)
        {
            Caption = 'Id';
            ObsoleteState = Removed;
            ObsoleteReason = 'This functionality will be replaced by the systemID field';
            ObsoleteTag = '22.0';
        }
        field(12400; "Director No."; Code[20])
        {
            Caption = 'Director No.';
            TableRelation = Employee;

            trigger OnValidate()
            begin
                "Director Name" := StdRepMgt.GetEmpName("Director No.");
            end;
        }
        field(12401; "Director Name"; Text[50])
        {
            Caption = 'Director Name';
        }
        field(12402; "Accountant Name"; Text[50])
        {
            Caption = 'Accountant Name';
        }
        field(12403; "Accountant No."; Code[20])
        {
            Caption = 'Accountant No.';
            TableRelation = Employee;

            trigger OnValidate()
            begin
                "Accountant Name" := StdRepMgt.GetEmpName("Accountant No.");
            end;
        }
        field(12404; "OGRN Code"; Code[13])
        {
            Caption = 'OGRN Code';
        }
        field(12405; "OKPO Code"; Code[10])
        {
            Caption = 'OKPO Code';
        }
        field(12406; "OKONX Code"; Code[10])
        {
            Caption = 'OKONX Code';
        }
        field(12407; "OKOPF Code"; Code[10])
        {
            Caption = 'OKOPF Code';
        }
        field(12408; "OKFS Code"; Code[10])
        {
            Caption = 'OKFS Code';
        }
        field(12409; "Full Name"; Text[250])
        {
            Caption = 'Full Name';
        }
        field(12410; "Bank BIC"; Code[20])
        {
            Caption = 'Bank BIC';
            TableRelation = "Bank Directory".BIC;
            ValidateTableRelation = false;

            trigger OnValidate()
            begin
                if BankDir.Get("Bank BIC") then begin
                    "Bank Corresp. Account No." := BankDir."Corr. Account No.";
                    "Bank Name" := CopyStr(BankDir."Full Name", 1, MaxStrLen("Bank Name"));
                    "Bank City" := BankDir."Area Name";
                end;
            end;
        }
        field(12411; "Recipient Tax Authority SONO"; Code[4])
        {
            Caption = 'Recipient Tax Authority SONO';
        }
        field(12412; "Admin. Tax Authority SONO"; Code[4])
        {
            Caption = 'Admin. Tax Authority SONO';
        }
        field(12416; "Region Code"; Code[10])
        {
            Caption = 'Region Code';
            //The property 'ValidateTableRelation' can only be set if the property 'TableRelation' is set
            //ValidateTableRelation = false;
        }
        field(12417; "Populated Locality"; Text[30])
        {
            Caption = 'Populated Locality';
        }
        field(12418; Street; Text[30])
        {
            Caption = 'Street';
        }
        field(12419; House; Text[5])
        {
            Caption = 'House';
        }
        field(12420; Building; Text[5])
        {
            Caption = 'Building';
        }
        field(12421; Apartment; Text[5])
        {
            Caption = 'Apartment';
        }
        field(12425; "KPP Code"; Code[10])
        {
            Caption = 'KPP Code';
        }
        field(12426; Status; Option)
        {
            Caption = 'Status';
            OptionCaption = 'Russian Entity,Subsidiary,Private,Foreign Entity Subsidiary,Other Entity';
            OptionMembers = "Russian Entity",Subsidiary,Private,"Foreign Entity Subsidiary","Other Entity";
        }
        field(12435; "Registration Date"; Date)
        {
            Caption = 'Registration Date';
        }
        field(12436; "Principal Activity"; Text[30])
        {
            Caption = 'Principal Activity';
        }
        field(12443; "OKOGU Code"; Code[10])
        {
            Caption = 'OKOGU Code';
        }
        field(12444; "OKATO Code"; Code[11])
        {
            Caption = 'OKATO Code';
        }
        field(12445; "OKVED Code"; Code[10])
        {
            Caption = 'OKVED Code';
        }
        field(12446; "HR Manager No."; Code[20])
        {
            Caption = 'HR Manager No.';
            TableRelation = Employee;
        }
        field(12450; "Taxation Body No."; Code[10])
        {
            Caption = 'Taxation Body No.';
        }
        field(12451; "Taxation Body Name"; Text[40])
        {
            Caption = 'Taxation Body Name';
        }
        field(12452; "Taxation Body District"; Text[30])
        {
            Caption = 'Taxation Body District';
        }
        field(12453; "Taxation Body Address"; Text[30])
        {
            Caption = 'Taxation Body Address';
        }
        field(12454; "Taxation Body Address 2"; Text[50])
        {
            Caption = 'Taxation Body Address 2';
        }
        field(12455; "Taxation Body Post Code"; Code[10])
        {
            Caption = 'Taxation Body Post Code';
        }
        field(12456; "Taxation Body Phone No."; Text[30])
        {
            Caption = 'Taxation Body Phone No.';
        }
        field(12457; "Pension Fund Registration No."; Text[20])
        {
            Caption = 'Pension Fund Registration No.';
        }
        field(12458; "Medical Fund Registration No."; Text[20])
        {
            Caption = 'Medical Fund Registration No.';
        }
        field(12459; "Social Insurance Fund Agency"; Text[35])
        {
            Caption = 'Social Insurance Fund Agency';
        }
        field(12460; "Social Insurance Code"; Text[10])
        {
            Caption = 'Social Insurance Code';
        }
        field(12461; "Tax Bearer Category"; Text[50])
        {
            Caption = 'Tax Bearer Category';
        }
        field(12462; "Tax Bearer Category Code"; Code[10])
        {
            Caption = 'Tax Bearer Category Code';
        }
        field(12463; "Pension Fund Registration Name"; Text[50])
        {
            Caption = 'Pension Fund Registration Name';
        }
        field(12464; "Bank City"; Text[50])
        {
            Caption = 'Bank City';
        }
        field(12478; "Bank Corresp. Account No."; Code[20])
        {
            Caption = 'Bank Corresp. Account No.';
        }
        field(12479; "Company Status"; Option)
        {
            Caption = 'Company Status';
            OptionCaption = ' ,01,02,03,04,05,06,07,08';
            OptionMembers = " ","01","02","03","04","05","06","07","08";
        }
        field(12480; "Administrative Region"; Text[50])
        {
            Caption = 'Administrative Region';
        }
        field(12481; "Primary Activity"; Text[50])
        {
            Caption = 'Primary Activity';
        }
        field(12482; "Form of Ownership"; Text[50])
        {
            Caption = 'Form of Ownership';
        }
        field(12483; "Separated Org. Unit"; Boolean)
        {
            Caption = 'Separated Org. Unit';
        }
        field(12485; "Region Name"; Text[30])
        {
            Caption = 'Region Name';
        }
        field(12487; "Municipal District"; Code[10])
        {
            Caption = 'Municipal District';
        }
        field(12488; "FSI Registration No."; Code[10])
        {
            Caption = 'FSI Registration No.';
        }
        field(14716; "Reg. Country/Region"; Text[50])
        {
            Caption = 'Reg. Country/Region';
        }
        field(14717; "Reg. Country/Region Code"; Code[10])
        {
            Caption = 'Reg. Country/Region Code';
            TableRelation = "Country/Region";
            ValidateTableRelation = false;

            trigger OnValidate()
            var
                Country: Record "Country/Region";
            begin
                "Reg. Country/Region" := Country.GetLocalName("Reg. Country/Region Code");
            end;
        }
        field(14718; "Reg. VAT Registration No."; Text[30])
        {
            Caption = 'Reg. VAT Registration No.';
        }
        field(14719; "Property Locat. KPP Code"; Code[10])
        {
            Caption = 'Property Locat. KPP Code';
        }
        field(14720; "Stat. Acc. Sert. - Series"; Code[20])
        {
            Caption = 'Stat. Acc. Sert. - Series';
        }
        field(14721; "Stat. Acc. Sert. - No."; Code[20])
        {
            Caption = 'Stat. Acc. Sert. - No.';
        }
        field(14722; "Stat. Acc. Sert. - Issue Date"; Date)
        {
            Caption = 'Stat. Acc. Sert. - Issue Date';
        }
        field(14723; "Stat. Acc. Sert. - Issue State"; Text[50])
        {
            Caption = 'Stat. Acc. Sert. - Issue State';
        }
        field(14724; "Stat. Acc. Sert. - Issue Code"; Code[20])
        {
            Caption = 'Stat. Acc. Sert. - Issue Code';
        }
        field(14725; "Representative Organization"; Text[30])
        {
            Caption = 'Representative Organization';
        }
        field(14726; "Representative First Name"; Text[30])
        {
            Caption = 'Representative First Name';
        }
        field(14727; "Representative Middle Name"; Text[30])
        {
            Caption = 'Representative Middle Name';
        }
        field(14728; "Representative Last Name"; Text[30])
        {
            Caption = 'Representative Last Name';
        }
        field(14729; "Representative Document"; Text[30])
        {
            Caption = 'Representative Document';
        }
        field(14730; "Import Curr. Exch. Rates"; Boolean)
        {
            Caption = 'Import Curr. Exch. Rates';
        }
        field(14731; "Import Conflict Resolution"; Option)
        {
            Caption = 'Import Conflict Resolution';
            OptionCaption = 'Replace,Skip,Prompt';
            OptionMembers = Replace,Skip,Prompt;
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
        PictureUpdated: Boolean;
        RecordHasBeenRead: Boolean;

        NotValidIBANErr: Label 'The number %1 that you entered may not be a valid International Bank Account Number (IBAN). Do you want to continue?', Comment = '%1 - an actual IBAN';
        NoPaymentInfoQst: Label 'No payment information is provided in %1. Do you want to update it now?', Comment = '%1 = Company Information';
        NoPaymentInfoMsg: Label 'No payment information is provided in %1. Review the report.';
        BankDir: Record "Bank Directory";
        StdRepMgt: Codeunit "Local Report Management";
        Text14900: Label 'Currency %1 exchange rate in company %2 on %3 already exists. Do you want to replace it?';
        GLNCheckDigitErr: Label 'The %1 is not valid.';
        DevBetaModeTxt: Label 'DEV_BETA', Locked = true;
        ContactUsFullTxt: Label 'Questions? Contact us at %1 or %2.', Comment = '%1 = phone number, %2 = email';
        ContactUsShortTxt: Label 'Questions? Contact us at %1.', Comment = '%1 = phone number or email';
        AlTelemetryCategoryTxt: Label 'AL CompanyInfo', Locked = true;
        EmptyCountryRegionErr: Label 'Country/Region code is not set, falling back to application default: %1.', Locked = true;

    procedure CheckIBAN(IBANCode: Code[100])
    var
        OriginalIBANCode: Code[100];
        Modulus97: Integer;
        I: Integer;
    begin
        OnBeforeCheckIBAN(IBANCode);

        if IBANCode = '' then
            exit;
        OriginalIBANCode := IBANCode;
        IBANCode := DelChr(IBANCode);
        Modulus97 := 97;
        if (StrLen(IBANCode) <= 5) or (StrLen(IBANCode) > 34) then
            IBANError(OriginalIBANCode);
        if IsDigit(IBANCode[1]) or IsDigit(IBANCode[2]) then
            IBANError(OriginalIBANCode);
        ConvertIBAN(IBANCode);
        while StrLen(IBANCode) > 6 do
            IBANCode := CalcModulus(CopyStr(IBANCode, 1, 6), Modulus97) + CopyStr(IBANCode, 7);
        Evaluate(I, IBANCode);
        if (I mod Modulus97) <> 1 then
            IBANError(OriginalIBANCode);
    end;

    procedure ConvertIBAN(var IBANCode: Code[100])
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

    procedure CalcModulus(Number: Code[10]; Modulus97: Integer): Code[10]
    var
        I: Integer;
    begin
        Evaluate(I, Number);
        I := I mod Modulus97;
        if I = 0 then
            exit('');
        exit(Format(I));
    end;

    procedure ConvertLetter(var IBANCode: Code[100]; Letter: Code[1]; LetterPlace: Integer): Boolean
    var
        Letter2: Code[2];
        LetterCharInt: Integer;
    begin
        // CFR assumes letter to number conversion where A = 10, B = 11, ... , Y = 34, Z = 35
        // We must ignore country alphabet feature like Estonian
        LetterCharInt := Letter[1];
        if LetterCharInt in [65 .. 90] then begin
            Letter2 := Format(LetterCharInt - 55, 9);
            case LetterPlace of
                1:
                    IBANCode := Letter2 + CopyStr(IBANCode, 2);
                StrLen(IBANCode):
                    IBANCode := CopyStr(IBANCode, 1, LetterPlace - 1) + Letter2;
                else
                    IBANCode :=
                      CopyStr(IBANCode, 1, LetterPlace - 1) + Letter2 + CopyStr(IBANCode, LetterPlace + 1);
            end;
            exit(true);
        end;
        if IsDigit(Letter[1]) then
            exit(false);

        IBANError(IBANCode);
    end;

    procedure IsDigit(LetterChar: Char): Boolean
    var
        Letter: Code[1];
    begin
        Letter[1] := LetterChar;
        exit((Letter >= '0') and (Letter <= '9'))
    end;

    procedure IBANError(WrongIBAN: Text)
    var
        ConfirmManagement: Codeunit "Confirm Management";
        IsHandled: Boolean;
    begin
        OnBeforeIBANError(IsHandled, WrongIBAN);
        if IsHandled then
            exit;
        if not ConfirmManagement.GetResponseOrDefault(StrSubstNo(NotValidIBANErr, WrongIBAN), true) then
            Error('');
    end;

    procedure DisplayMap()
    var
        OnlineMapManagement: Codeunit "Online Map Management";
    begin
        OnlineMapManagement.MakeSelectionIfMapEnabled(Database::"Company Information", GetPosition());
    end;

    local procedure IsPaymentInfoAvailble(): Boolean
    begin
        exit(
          (("Giro No." + IBAN + "Bank Name" + "Bank Branch No." + "Bank Account No." + "SWIFT Code") <> '') or
          "Allow Blank Payment Info.");
    end;

    procedure GetRegistrationNumber() Result: Text
    begin
        Result := "Registration No.";
        OnAfterGetRegistrationNumber(Result);
    end;

    procedure GetRegistrationNumberLbl() Result: Text
    begin
        Result := FieldCaption("Registration No.");
        OnAfterGetRegistrationNumberLbl(Result);
    end;

    procedure GetVATRegistrationNumber() Result: Text
    begin
        Result := "VAT Registration No.";
        OnAfterGetVATRegistrationNumber(Result);
    end;

    procedure GetVATRegistrationNumberLbl() Result: Text
    var
        IsHandled: Boolean;
    begin
        if Name = '' then // Is the record loaded?
            Get();

        IsHandled := false;
        OnBeforeGetVATRegistrationNumberLbl(Result, IsHandled);
        if IsHandled then
            exit(Result);

        if "VAT Registration No." = '' then
            exit('');
        exit(FieldCaption("VAT Registration No."));
    end;

#if not CLEAN23
    [Obsolete('The procedure is not used and will be obsoleted', '23.0')]
    procedure GetLegalOffice(): Text
    begin
        exit('');
    end;

    [Obsolete('The procedure is not used and will be obsoleted', '23.0')]
    procedure GetLegalOfficeLbl(): Text
    begin
        exit('');
    end;

    [Obsolete('The procedure is not used and will be obsoleted', '23.0')]
    procedure GetCustomGiro(): Text
    begin
        exit('');
    end;

    [Obsolete('The procedure is not used and will be obsoleted', '23.0')]
    procedure GetCustomGiroLbl(): Text
    begin
        exit('');
    end;
#endif

    procedure GetRecordOnce()
    begin
        if RecordHasBeenRead then
            exit;
        Get();
        RecordHasBeenRead := true;
    end;

    procedure VerifyAndSetPaymentInfo()
    var
        ConfirmManagement: Codeunit "Confirm Management";
        CompanyInformationPage: Page "Company Information";
    begin
        Get();
        if IsPaymentInfoAvailble() then
            exit;
        if GuiAllowed then begin
            if ConfirmManagement.GetResponseOrDefault(StrSubstNo(NoPaymentInfoQst, TableCaption), true) then begin
                CompanyInformationPage.SetRecord(Rec);
                CompanyInformationPage.Editable(true);
                if CompanyInformationPage.RunModal() = ACTION::OK then
                    CompanyInformationPage.GetRecord(Rec);
            end;
            if not IsPaymentInfoAvailble() then
                Message(NoPaymentInfoMsg, TableCaption);
        end else
            Error(NoPaymentInfoMsg, TableCaption);
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

    [Scope('OnPrem')]
    procedure IsNeedToReplaceCurrExchRate(CurrencyCode: Code[10]; ExchRateDate: Date; CompName: Text[30]): Boolean
    begin
        case "Import Conflict Resolution" of
            "Import Conflict Resolution"::Skip:
                exit(false);

            "Import Conflict Resolution"::Replace:
                exit(true);

            "Import Conflict Resolution"::Prompt:
                exit(Confirm(Text14900, true, CurrencyCode, CompName, ExchRateDate));
        end;
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

        Session.LogMessage('00007HP', StrSubstNo(EmptyCountryRegionErr, CountryRegionCode), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', AlTelemetryCategoryTxt);

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

    [IntegrationEvent(true, false)]
    local procedure OnBeforeIBANError(var IsHandled: Boolean; WrongIBAN: Text)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterGetRegistrationNumber(var Result: Text)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterGetRegistrationNumberLbl(var Result: Text)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterGetVATRegistrationNumber(var Result: Text)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeGetVATRegistrationNumberLbl(var Result: Text; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckIBAN(IBANCode: Code[100])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateCity(var CompanyInformation: Record "Company Information"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidatePostCode(var CompanyInformation: Record "Company Information"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateShipToCity(var CompanyInformation: Record "Company Information"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateShipToPostCode(var CompanyInformation: Record "Company Information"; var IsHandled: Boolean)
    begin
    end;
}

