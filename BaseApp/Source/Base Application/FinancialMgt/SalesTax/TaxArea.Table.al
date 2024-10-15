namespace Microsoft.Finance.SalesTax;

using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;
using Microsoft.Sales.History;
using System.Globalization;

table 318 "Tax Area"
{
    Caption = 'Tax Area';
    DataCaptionFields = "Code", Description;
    LookupPageID = "Tax Area List";

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
        field(10; "Last Modified Date Time"; DateTime)
        {
            Caption = 'Last Modified Date Time';
            Editable = false;
        }
        field(8000; Id; Guid)
        {
            Caption = 'Id';
            ObsoleteState = Removed;
            ObsoleteReason = 'This functionality will be replaced by the systemID field';
            ObsoleteTag = '22.0';
        }
        field(10010; "Country/Region"; Option)
        {
            BlankZero = false;
            Caption = 'Country/Region';
            OptionCaption = 'US,CA';
            OptionMembers = US,CA;

            trigger OnValidate()
            begin
                TaxAreaLine.SetRange("Tax Area", Code);
                if TaxAreaLine.Find('-') then begin
                    repeat
                        TaxJurisdiction.Get(TaxAreaLine."Tax Jurisdiction Code");
                        TestField("Country/Region", TaxJurisdiction."Country/Region");
                    until TaxAreaLine.Next() = 0;
                end;
            end;
        }
        field(10011; "Round Tax"; Option)
        {
            BlankZero = false;
            Caption = 'Round Tax';
            OptionCaption = 'To Nearest,Up,Down';
            OptionMembers = "To Nearest",Up,Down;
        }
        field(10012; "Use External Tax Engine"; Boolean)
        {
            Caption = 'Use External Tax Engine';
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
    begin
        if IsTaxAreaInUse() then
            Error(TaxAreaInUseErr);

        TaxAreaLine.SetRange("Tax Area", Code);
        TaxAreaLine.DeleteAll();
    end;

    trigger OnInsert()
    begin
        SetLastModifiedDateTime();
    end;

    trigger OnModify()
    begin
        SetLastModifiedDateTime();
    end;

    trigger OnRename()
    begin
        SetLastModifiedDateTime();
    end;

    var
        TaxAreaLine: Record "Tax Area Line";
        TaxJurisdiction: Record "Tax Jurisdiction";
        TaxAreaInUseErr: Label 'You cannot delete this tax rate because it is used on one or more existing documents.';

    procedure CreateTaxArea(NewTaxAreaCode: Code[20]; City: Text[50]; State: Text[50])
    begin
        Init();
        Code := NewTaxAreaCode;
        Description := NewTaxAreaCode;
        if Insert() then;

        if City <> '' then
            CreateTaxAreaLine(Code, CopyStr(City, 1, 10));
        if State <> '' then
            CreateTaxAreaLine(Code, CopyStr(State, 1, 10));
        if (City = '') and (State = '') then
            CreateTaxAreaLine(Code, CopyStr(NewTaxAreaCode, 1, 10));
    end;

    local procedure CreateTaxAreaLine(NewTaxArea: Code[20]; NewJurisdictionCode: Code[10])
    var
        TaxAreaLine: Record "Tax Area Line";
        TaxJurisdiction: Record "Tax Jurisdiction";
    begin
        if TaxAreaLine.Get(NewTaxArea, NewJurisdictionCode) then
            exit;
        TaxAreaLine.Init();
        TaxAreaLine."Tax Area" := NewTaxArea;
        TaxAreaLine."Tax Jurisdiction Code" := NewJurisdictionCode;
        TaxAreaLine.Insert();
        TaxJurisdiction.CreateTaxJurisdiction(NewJurisdictionCode);
    end;

#if not CLEAN21
    [Obsolete('Replaced with GetDescriptionInCurrentLanguageFullLength.', '21.0')]
    procedure GetDescriptionInCurrentLanguage(): Text[50]
    var
        TaxAreaTranslation: Record "Tax Area Translation";
        Language: Codeunit Language;
    begin
        if TaxAreaTranslation.Get(Code, Language.GetUserLanguageCode()) then
            exit(CopyStr(TaxAreaTranslation.Description, 1, 50));

        exit(CopyStr(Description, 1, 50));
    end;
#endif

    procedure GetDescriptionInCurrentLanguageFullLength(): Text[100]
    var
        TaxAreaTranslation: Record "Tax Area Translation";
        Language: Codeunit Language;
    begin
        if TaxAreaTranslation.Get(Code, Language.GetUserLanguageCode()) then
            exit(TaxAreaTranslation.Description);

        exit(Description);
    end;

    local procedure SetLastModifiedDateTime()
    begin
        "Last Modified Date Time" := CurrentDateTime;
    end;

    local procedure IsTaxAreaInUse(): Boolean
    var
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        Customer: Record Customer;
    begin
        Customer.SetRange("Tax Area Code", Code);
        if not Customer.IsEmpty() then
            exit(true);

        SalesHeader.SetRange("Tax Area Code", Code);
        if not SalesHeader.IsEmpty() then
            exit(true);

        SalesInvoiceHeader.SetRange("Tax Area Code", Code);
        if not SalesInvoiceHeader.IsEmpty() then
            exit(true);

        exit(false);
    end;
}
