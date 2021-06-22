page 1162 "Purchase Invoice Due Next Week"
{
    Caption = '<Purchase Invoices Due Next Week>';
    DeleteAllowed = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = CardPart;
    ShowFilter = false;
    SourceTable = "Vendor Ledger Entry";
    SourceTableView = SORTING("Entry No.")
                      ORDER(Descending);

    layout
    {
        area(content)
        {
            repeater(Control8)
            {
                ShowCaption = false;
                field("Posting Date"; "Posting Date")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies which purchase invoices are due next week.';
                }
                field("Document Type"; "Document Type")
                {
                    ApplicationArea = All;
                    StyleExpr = StyleTxt;
                    ToolTip = 'Specifies the type of document.';
                }
                field("Document No."; "Document No.")
                {
                    ApplicationArea = All;
                    StyleExpr = StyleTxt;
                    ToolTip = 'Specifies the purchase invoice number.';
                }
                field("Vendor Name"; VendorName)
                {
                    ApplicationArea = All;
                    Caption = 'Vendor Name';
                    ToolTip = 'Specifies name of the Vendor.';
                }
                field("Remaining Amount"; "Remaining Amount")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the amount that remains to be paid on the purchase invoice that is due next week.';

                    trigger OnDrillDown()
                    var
                        HyperLinkUrl: Text[250];
                    begin
                        HyperLinkUrl := GetUrl(CLIENTTYPE::Web, CompanyName, OBJECTTYPE::Page, 574) + StrSubstNo(FilterForRemAmtDrillDwnTxt, "Entry No.");
                        HyperLink(HyperLinkUrl);
                    end;
                }
                field("Due Date"; "Due Date")
                {
                    ApplicationArea = All;
                    StyleExpr = StyleTxt;
                    ToolTip = 'Specifies when the purchase invoice must be paid.';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetRecord()
    var
        Vendor: Record Vendor;
    begin
        Vendor.Get("Vendor No.");
        VendorName := Vendor.Name;
        StyleTxt := SetStyle;
    end;

    trigger OnOpenPage()
    begin
        SetRange(Open, true);
        SetFilter("Document Type", 'Invoice|Credit Memo');
        SetFilter("Due Date", '%1..%2', CalcDate('<1D>', WorkDate), CalcDate('<1W>', WorkDate));
        Ascending := false;
    end;

    var
        VendorName: Text[250];
        StyleTxt: Text;
        FilterForRemAmtDrillDwnTxt: Label '&filter=''Detailed Vendor Ledg. Entry''.''Vendor Ledger Entry No.'' IS ''%1''', Comment = '%1 - Entry No. for Vendor ledger entry. ';
}

