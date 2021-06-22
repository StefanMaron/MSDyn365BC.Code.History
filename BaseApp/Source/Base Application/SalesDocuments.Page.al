page 1160 "Sales Documents"
{
    Caption = 'Sales Documents';
    DeleteAllowed = false;
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = ListPart;
    SourceTable = "Cust. Ledger Entry";
    SourceTableView = SORTING("Entry No.")
                      ORDER(Descending);

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Due Date"; "Due Date")
                {
                    ApplicationArea = All;
                    StyleExpr = StyleTxt;
                    ToolTip = 'Specifies when the sales documents are due.';
                }
                field("Document Type"; "Document Type")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the type of sales document.';
                }
                field("Document No."; "Document No.")
                {
                    ApplicationArea = All;
                    StyleExpr = StyleTxt;
                    ToolTip = 'Specifies the sales document number.';
                }
                field("Customer Name"; CustomerName)
                {
                    ApplicationArea = All;
                    Caption = 'Customer Name';
                    ToolTip = 'Specifies customer name.';
                }
                field("Remaining Amount"; "Remaining Amount")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the amount that remains to be paid on the sales documents.';

                    trigger OnDrillDown()
                    var
                        Company: Record Company;
                        ConfPersonalizationMgt: Codeunit "Conf./Personalization Mgt.";
                        HyperLinkUrl: Text[500];
                    begin
                        Company.Get(CompanyName);
                        if Company."Evaluation Company" then
                            HyperLinkUrl := GetUrl(CLIENTTYPE::Web, CompanyName, OBJECTTYPE::Page, 573) +
                              '&' + ConfPersonalizationMgt.GetProfileUrlParameterForEvaluationCompany()
                               + StrSubstNo(FilterForRemAmtDrillDwnTxt, "Entry No.")
                        else
                            HyperLinkUrl := GetUrl(CLIENTTYPE::Web, CompanyName, OBJECTTYPE::Page, 573) + StrSubstNo(FilterForRemAmtDrillDwnTxt, "Entry No.");
                        HyperLink(HyperLinkUrl);
                    end;
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
        }
    }

    trigger OnAfterGetRecord()
    var
        Customer: Record Customer;
    begin
        Customer.Get("Customer No.");
        CustomerName := Customer.Name;
        StyleTxt := SetStyle;
    end;

    trigger OnOpenPage()
    begin
        SetRange("Document Type", "Document Type"::Invoice);
        SetRange(Open, true);
        SetFilter("Due Date", '<%1', WorkDate);
        SetFilter("Remaining Amt. (LCY)", '<>0');
        SetCurrentKey("Remaining Amt. (LCY)");
        Ascending := false;
    end;

    var
        StyleTxt: Text;
        CustomerName: Text[100];
        FilterForRemAmtDrillDwnTxt: Label '&filter=''Detailed Cust. Ledg. Entry''.''Cust. Ledger Entry No.'' IS ''%1''', Comment = '%1 - Entry No. for Vendor ledger entry. ';

    procedure SetFilterForOverdueSalesInvoiceAmount()
    begin
        Reset;
        SetRange("Document Type", "Document Type"::Invoice);
        SetRange(Open, true);
        SetFilter("Due Date", '<%1', WorkDate);
        SetFilter("Remaining Amt. (LCY)", '<>0');
        SetCurrentKey("Remaining Amt. (LCY)");
        Ascending := false;
        CurrPage.Update;
    end;

    procedure SetFilterForSalesDocsDueToday()
    begin
        Reset;
        SetFilter("Document Type", 'Invoice|Credit Memo');
        SetFilter("Due Date", '<=%1', WorkDate);
        SetRange(Open, true);
        Ascending := false;
        CurrPage.Update;
    end;

    procedure SetFilterForSalesDocsDueNextWeek()
    begin
        Reset;
        SetFilter("Document Type", 'Invoice|Credit Memo');
        SetFilter("Due Date", '%1..%2', CalcDate('<1D>', WorkDate), CalcDate('<1W>', WorkDate));
        SetRange(Open, true);
        Ascending := false;
        CurrPage.Update;
    end;
}

