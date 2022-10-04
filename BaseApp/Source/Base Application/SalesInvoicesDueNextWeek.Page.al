page 1163 "Sales Invoices Due Next Week"
{
    Caption = 'Sales Invoices Due Next Week';
    DeleteAllowed = false;
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = CardPart;
    ShowFilter = false;
    SourceTable = "Sales Invoice Header";
    SourceTableView = SORTING("Posting Date")
                      ORDER(Descending);

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Due Date"; Rec."Due Date")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies when the sales invoices must be paid.';
                }
                field("No."; Rec."No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
                }
                field("Sell-to Customer Name"; Rec."Sell-to Customer Name")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the name of the customer.';
                }
                field("Remaining Amount"; Rec."Remaining Amount")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the amount that remains to be paid on the sales invoices that are due next week.';

                    trigger OnDrillDown()
                    var
                        HyperLinkUrl: Text[250];
                    begin
                        HyperLinkUrl := GetUrl(CLIENTTYPE::Web, CompanyName, OBJECTTYPE::Page, 573) +
                          StrSubstNo(FilterForRemAmountDrillDwnTxt, "Cust. Ledger Entry No.");
                        HyperLink(HyperLinkUrl);
                    end;
                }
                field("Currency Code"; Rec."Currency Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the relevant currency code for the sales invoices.';
                }
                field(Closed; Closed)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies whether or not the sales invoice on the line has been closed.';

                    trigger OnDrillDown()
                    var
                        HyperLinkUrl: Text[250];
                    begin
                        HyperLinkUrl := GetUrl(CLIENTTYPE::Web, CompanyName, OBJECTTYPE::Page, 25) +
                          StrSubstNo(FilterForClosedDrillDwnTxt, "Cust. Ledger Entry No.");
                        HyperLink(HyperLinkUrl);
                    end;
                }
            }
        }
    }

    actions
    {
    }

    trigger OnOpenPage()
    begin
        SetRange(Closed, false);
        SetFilter("Due Date", '%1..%2', CalcDate('<1D>', WorkDate()), CalcDate('<1W>', WorkDate()));
        Ascending := false;
    end;

    var
        FilterForClosedDrillDwnTxt: Label '&filter=''Cust. Ledger Entry''.''Entry No.'' IS ''%1'' AND ''Cust. Ledger Entry''.Open IS ''1''', Comment = '%1 - Customer ledger Entry No. for sales invoice header.';
        FilterForRemAmountDrillDwnTxt: Label '&filter=''Detailed Cust. Ledg. Entry''.''Cust. Ledger Entry No.'' IS ''%1''', Comment = '%1 - Customer ledger Entry No. for sales invoice header.';
}

