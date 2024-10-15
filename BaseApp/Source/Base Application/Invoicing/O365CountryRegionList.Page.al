#if not CLEAN21
page 2152 "O365 Country/Region List"
{
    Caption = 'Countries/Regions';
    CardPageID = "O365 Country/Region Card";
    DeleteAllowed = false;
    LinksAllowed = false;
    ModifyAllowed = false;
    PageType = List;
    RefreshOnActivate = true;
    SourceTable = "O365 Country/Region";
    SourceTableTemporary = true;
    ObsoleteReason = 'Microsoft Invoicing has been discontinued.';
    ObsoleteState = Pending;
    ObsoleteTag = '21.0';

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Code"; Rec.Code)
                {
                    ApplicationArea = Invoicing, Basic, Suite;
                }
                field(Name; Rec.Name)
                {
                    ApplicationArea = Invoicing, Basic, Suite;
                    ToolTip = 'Specifies the name.';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnFindRecord(Which: Text): Boolean
    var
        CountryRegion: Record "Country/Region";
    begin
        if CountryRegion.FindSet() then
            repeat
                Rec.Code := CountryRegion.Code;
                Rec.Name := CountryRegion.GetNameInCurrentLanguage();
                Rec."VAT Scheme" := CountryRegion."VAT Scheme";
                if Rec.Insert() then;
            until CountryRegion.Next() = 0;

        exit(Rec.Find(Which));
    end;

    trigger OnOpenPage()
    begin
        Rec.DeleteAll();
    end;
}
#endif
