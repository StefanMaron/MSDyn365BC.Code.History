page 30011 "APIV2 - Company Information"
{
    APIVersion = 'v2.0';
    EntityCaption = 'Company Information';
    EntitySetCaption = 'Company Information';
    DelayedInsert = true;
    DeleteAllowed = false;
    EntityName = 'companyInformation';
    EntitySetName = 'companyInformation';
    InsertAllowed = false;
    ODataKeyFields = SystemId;
    PageType = API;
    SaveValues = true;
    SourceTable = "Company Information";
    Extensible = false;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field(id; SystemId)
                {
                    Caption = 'Id';
                    Editable = false;
                }
                field(displayName; Name)
                {
                    Caption = 'Display Name';
                }
                field(addressLine1; Address)
                {
                    Caption = 'Address Line 1';
                }
                field(addressLine2; "Address 2")
                {
                    Caption = 'Address Line 2';
                }
                field(city; City)
                {
                    Caption = 'City';
                }
                field(state; County)
                {
                    Caption = 'State';
                }
                field(country; "Country/Region Code")
                {
                    Caption = 'Country/Region Code';
                }
                field(postalCode; "Post Code")
                {
                    Caption = 'Post Code';
                }
                field(phoneNumber; "Phone No.")
                {
                    Caption = 'Phone No.';
                }
                field(faxNumber; "Fax No.")
                {
                    Caption = 'Fax No.';
                }
                field(email; "E-Mail")
                {
                    Caption = 'Email';
                }
                field(website; "Home Page")
                {
                    Caption = 'Website';
                }
                field(taxRegistrationNumber; "VAT Registration No.")
                {
                    Caption = 'Tax Registration No.';
                }
                field(currencyCode; LCYCurrencyCode)
                {
                    Caption = 'Currency Code';
                    Editable = false;
                }
                field(currentFiscalYearStartDate; FiscalYearStart)
                {
                    Caption = 'Current Fiscal Year Start Date';
                    Editable = false;
                }
                field(industry; "Industrial Classification")
                {
                    Caption = 'Industry';
                }
                field(picture; Picture)
                {
                    Caption = 'Picture';
                    Editable = false;
                }
                field(lastModifiedDateTime; SystemModifiedAt)
                {
                    Caption = 'Last Modified Date';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetRecord()
    begin
        SetCalculatedFields();
    end;

    trigger OnModifyRecord(): Boolean
    var
        CompanyInformation: Record "Company Information";
    begin
        CompanyInformation.GetBySystemId(SystemId);
        Modify(true);

        SetCalculatedFields();
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        ClearCalculatedFields();
    end;

    var
        LCYCurrencyCode: Code[10];
        FiscalYearStart: Date;

    local procedure SetCalculatedFields()
    var
        AccountingPeriod: Record "Accounting Period";
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        LCYCurrencyCode := GeneralLedgerSetup."LCY Code";

        AccountingPeriod.SetRange("New Fiscal Year", true);
        if AccountingPeriod.FindLast() then
            FiscalYearStart := AccountingPeriod."Starting Date";
    end;

    local procedure ClearCalculatedFields()
    begin
        Clear(SystemId);
    end;
}

