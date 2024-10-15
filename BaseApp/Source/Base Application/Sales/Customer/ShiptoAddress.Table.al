namespace Microsoft.Sales.Customer;

using Microsoft.EServices.OnlineMap;
using Microsoft.CRM.Team;
using Microsoft.Finance.SalesTax;
using Microsoft.Foundation.Address;
using Microsoft.Foundation.Shipping;
using Microsoft.Inventory.Location;
using Microsoft.Service.Setup;
using Microsoft.Utilities;
using System.Email;
using Microsoft.eServices.EDocument;

table 222 "Ship-to Address"
{
    Caption = 'Ship-to Address';
    DataCaptionFields = "Customer No.", Name, "Code";
    LookupPageID = "Ship-to Address List";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Customer No."; Code[20])
        {
            Caption = 'Customer No.';
            NotBlank = true;
            TableRelation = Customer;
        }
        field(2; "Code"; Code[10])
        {
            Caption = 'Code';
            NotBlank = true;
        }
        field(3; Name; Text[100])
        {
            Caption = 'Name';
        }
        field(4; "Name 2"; Text[50])
        {
            Caption = 'Name 2';
        }
        field(5; Address; Text[100])
        {
            Caption = 'Address';
        }
        field(6; "Address 2"; Text[50])
        {
            Caption = 'Address 2';
        }
        field(7; City; Text[30])
        {
            Caption = 'City';
            TableRelation = if ("Country/Region Code" = const('')) "Post Code".City
            else
            if ("Country/Region Code" = filter(<> '')) "Post Code".City where("Country/Region Code" = field("Country/Region Code"));
            ValidateTableRelation = false;

            trigger OnLookup()
            begin
                OnBeforeLookupCity(Rec, PostCode);

                PostCode.LookupPostCode(City, "Post Code", County, "Country/Region Code");

                OnAfterLookupCity(Rec, PostCode, xRec);
            end;

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateCity(Rec, PostCode, CurrFieldNo, IsHandled);
                if not IsHandled then
                    PostCode.ValidateCity(City, "Post Code", County, "Country/Region Code", (CurrFieldNo <> 0) and GuiAllowed);
                OnAfterValidateCity(Rec, PostCode);
            end;
        }
        field(8; Contact; Text[100])
        {
            Caption = 'Contact';
        }
        field(9; "Phone No."; Text[30])
        {
            Caption = 'Phone No.';
            ExtendedDatatype = PhoneNo;
        }
        field(10; "Telex No."; Text[30])
        {
            Caption = 'Telex No.';
        }
        field(29; "Salesperson Code"; Code[20])
        {
            Caption = 'Salesperson Code';
            TableRelation = "Salesperson/Purchaser" where(Blocked = const(false));

            trigger OnValidate()
            begin
                ValidateSalesPersonCode();
            end;
        }
        field(30; "Shipment Method Code"; Code[10])
        {
            Caption = 'Shipment Method Code';
            TableRelation = "Shipment Method";
        }
        field(31; "Shipping Agent Code"; Code[10])
        {
            AccessByPermission = TableData "Shipping Agent Services" = R;
            Caption = 'Shipping Agent Code';
            TableRelation = "Shipping Agent";

            trigger OnValidate()
            begin
                if "Shipping Agent Code" <> xRec."Shipping Agent Code" then
                    Validate("Shipping Agent Service Code", '');
            end;
        }
        field(32; "Place of Export"; Code[20])
        {
            Caption = 'Place of Export';
        }
        field(35; "Country/Region Code"; Code[10])
        {
            Caption = 'Country/Region Code';
            TableRelation = "Country/Region";

            trigger OnValidate()
            begin
                PostCode.CheckClearPostCodeCityCounty(City, "Post Code", County, "Country/Region Code", xRec."Country/Region Code");
            end;
        }
        field(54; "Last Date Modified"; Date)
        {
            Caption = 'Last Date Modified';
            Editable = false;
        }
        field(83; "Location Code"; Code[10])
        {
            Caption = 'Location Code';
            TableRelation = Location where("Use As In-Transit" = const(false));
        }
        field(84; "Fax No."; Text[30])
        {
            Caption = 'Fax No.';
        }
        field(85; "Telex Answer Back"; Text[20])
        {
            Caption = 'Telex Answer Back';
        }
        field(90; GLN; Code[13])
        {
            Caption = 'GLN';

            trigger OnValidate()
            var
                GLNCalculator: Codeunit "GLN Calculator";
            begin
                if GLN <> '' then
                    GLNCalculator.AssertValidCheckDigit13(GLN);
            end;
        }
        field(91; "Post Code"; Code[20])
        {
            Caption = 'Post Code';
            TableRelation = if ("Country/Region Code" = const('')) "Post Code"
            else
            if ("Country/Region Code" = filter(<> '')) "Post Code" where("Country/Region Code" = field("Country/Region Code"));
            ValidateTableRelation = false;

            trigger OnLookup()
            begin
                OnBeforeLookupPostCode(Rec, PostCode);

                PostCode.LookupPostCode(City, "Post Code", County, "Country/Region Code");

                OnAfterLookupPostCode(Rec, PostCode, xRec);
            end;

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidatePostCode(Rec, PostCode, CurrFieldNo, IsHandled);
                if not IsHandled then
                    PostCode.ValidatePostCode(City, "Post Code", County, "Country/Region Code", (CurrFieldNo <> 0) and GuiAllowed);
                OnAfterValidatePostCode(Rec, PostCode);
            end;
        }
        field(92; County; Text[30])
        {
            CaptionClass = '5,1,' + "Country/Region Code";
            Caption = 'County';
        }
        field(102; "E-Mail"; Text[80])
        {
            Caption = 'Email';
            ExtendedDatatype = EMail;

            trigger OnValidate()
            begin
                ValidateEmail()
            end;
        }
#if not CLEAN24
        field(103; "Home Page"; Text[80])
        {
            Caption = 'Home Page';
            ExtendedDatatype = URL;
            ObsoleteReason = 'Field length will be increased to 255.';
            ObsoleteState = Pending;
            ObsoleteTag = '24.0';
        }
#else
#pragma warning disable AS0086
        field(103; "Home Page"; Text[255])
        {
            Caption = 'Home Page';
            ExtendedDatatype = URL;
        }
#pragma warning restore AS0086
#endif
        field(108; "Tax Area Code"; Code[20])
        {
            Caption = 'Tax Area Code';
            TableRelation = "Tax Area";
        }
        field(109; "Tax Liable"; Boolean)
        {
            Caption = 'Tax Liable';
        }
        field(5792; "Shipping Agent Service Code"; Code[10])
        {
            Caption = 'Shipping Agent Service Code';
            TableRelation = "Shipping Agent Services".Code where("Shipping Agent Code" = field("Shipping Agent Code"));
        }
        field(5900; "Service Zone Code"; Code[10])
        {
            Caption = 'Service Zone Code';
            TableRelation = "Service Zone";
        }
        field(10004; "UPS Zone"; Code[2])
        {
            Caption = 'UPS Zone';
        }
        field(27009; "SAT Address ID"; Integer)
        {
            Caption = 'SAT Address ID';
            TableRelation = "SAT Address";

            trigger OnLookup()
            var
                SATAddress: Record "SAT Address";
            begin
                if SATAddress.LookupSATAddress(SATAddress, Rec."Country/Region Code", '') then
                    Rec."SAT Address ID" := SATAddress.Id;
            end;
        }
    }

    keys
    {
        key(Key1; "Customer No.", "Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "Code", Name, Address, City, "Post Code")
        {
        }
    }

    trigger OnInsert()
    begin
        Cust.Get("Customer No.");
        Name := Cust.Name;
    end;

    trigger OnModify()
    begin
        "Last Date Modified" := Today;
    end;

    trigger OnRename()
    begin
        "Last Date Modified" := Today;
    end;

    var
        Cust: Record Customer;
        PostCode: Record "Post Code";

        Text000: Label 'untitled';

    procedure Caption(): Text
    begin
        if "Customer No." = '' then
            exit(Text000);
        Cust.Get("Customer No.");
        exit(StrSubstNo('%1 %2 %3 %4', Cust."No.", Cust.Name, Code, Name));
    end;

    procedure DisplayMap()
    var
        OnlineMapManagement: Codeunit "Online Map Management";
    begin
        OnlineMapManagement.MakeSelectionIfMapEnabled(Database::"Ship-to Address", GetPosition());
    end;

    procedure GetFilterCustNo(): Code[20]
    begin
        if GetFilter("Customer No.") <> '' then
            if GetRangeMin("Customer No.") = GetRangeMax("Customer No.") then
                exit(GetRangeMax("Customer No."));
    end;


    local procedure ValidateEmail()
    var
        MailManagement: Codeunit "Mail Management";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeValidateEmail(Rec, xRec, IsHandled);
        if IsHandled then
            exit;

        MailManagement.ValidateEmailAddressField("E-Mail");
    end;

    procedure GetSATPostalCode(): Code[20]
    var
        SATAddress: Record "SAT Address";
    begin
        if SATAddress.Get("SAT Address ID") then
            exit(SATAddress.GetSATPostalCode());
        exit('');
    end;

    local procedure ValidateSalesPersonCode()
    var
        SalespersonPurchaser: Record "Salesperson/Purchaser";
    begin
        if "Salesperson Code" = '' then
            exit;

        if not SalespersonPurchaser.Get("Salesperson Code") then
            exit;

        if SalespersonPurchaser.VerifySalesPersonPurchaserPrivacyBlocked(SalespersonPurchaser) then
            Error(SalespersonPurchaser.GetPrivacyBlockedGenericText(SalespersonPurchaser, true))
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterLookupPostCode(var ShipToAddress: Record "Ship-to Address"; var PostCodeRec: Record "Post Code"; xShipToAddress: Record "Ship-to Address");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterLookupCity(var ShipToAddress: Record "Ship-to Address"; var PostCodeRec: Record "Post Code"; xShipToAddress: Record "Ship-to Address");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterValidateCity(var ShipToAddress: Record "Ship-to Address"; var PostCode: Record "Post Code");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterValidatePostCode(var ShipToAddress: Record "Ship-to Address"; var PostCode: Record "Post Code");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeLookupCity(var ShipToAddress: Record "Ship-to Address"; var PostCodeRec: Record "Post Code");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeLookupPostCode(var ShipToAddress: Record "Ship-to Address"; var PostCodeRec: Record "Post Code");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateCity(var ShipToAddress: Record "Ship-to Address"; var PostCodeRec: Record "Post Code"; CurrentFieldNo: Integer; var IsHandled: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateEmail(var ShiptoAddress: Record "Ship-to Address"; xShiptoAddress: Record "Ship-to Address"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidatePostCode(var ShipToAddress: Record "Ship-to Address"; var PostCodeRec: Record "Post Code"; CurrentFieldNo: Integer; var IsHandled: Boolean);
    begin
    end;
}

