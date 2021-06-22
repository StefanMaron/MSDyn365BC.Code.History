page 2352 "BC O365 Country/Region List"
{
    Caption = 'Countries/Regions';
    CardPageID = "O365 Country/Region Card";
    DeleteAllowed = false;
    Editable = false;
    LinksAllowed = false;
    PageType = List;
    RefreshOnActivate = true;
    SourceTable = "O365 Country/Region";
    SourceTableTemporary = true;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Code"; Code)
                {
                    ApplicationArea = Basic, Suite, Invoicing;
                    ToolTip = 'Specifies the ISO code of the country or region.';

                    trigger OnValidate()
                    begin
                        if (xRec.Code <> '') and (Code <> xRec.Code) then
                            Error(RenameCountryErr);
                    end;
                }
                field(Name; Name)
                {
                    ApplicationArea = Basic, Suite, Invoicing;
                    ToolTip = 'Specifies the name of the country or region.';
                }
                field("VAT Scheme"; "VAT Scheme")
                {
                    ApplicationArea = Basic, Suite, Invoicing;
                    Visible = false;
                }
            }
        }
    }

    actions
    {
    }

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    begin
        exit(O365SalesManagement.InsertNewCountryCode(Rec));
    end;

    trigger OnModifyRecord(): Boolean
    begin
        exit(O365SalesManagement.ModifyCountryCode(xRec, Rec));
    end;

    trigger OnOpenPage()
    var
        CountryRegion: Record "Country/Region";
    begin
        DeleteAll();
        if CountryRegion.FindSet then
            repeat
                Code := CountryRegion.Code;
                Name := CountryRegion.GetNameInCurrentLanguage;
                if Insert() then;
            until CountryRegion.Next = 0;
        SetCurrentKey(Name);
    end;

    var
        O365SalesManagement: Codeunit "O365 Sales Management";
        RenameCountryErr: Label 'You cannot change the country code.';
}

