page 1159 "Purchase Documents"
{
    Caption = 'Purchase Documents';
    DataCaptionFields = "Vendor No.";
    PageType = ListPart;
    SourceTable = "Vendor Ledger Entry";
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
                    ToolTip = 'Specifies when the purchase document is due.';
                }
                field("Document Type"; "Document Type")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the type of document.';
                }
                field("Document No."; "Document No.")
                {
                    ApplicationArea = All;
                    StyleExpr = StyleTxt;
                    ToolTip = 'Specifies the purchase document number.';
                }
                field("Vendor Name"; VendorName)
                {
                    ApplicationArea = All;
                    Caption = 'Vendor Name';
                    ToolTip = 'Specifies name of the Vendor.';
                }
                field("Remaining Amount LCY"; "Remaining Amt. (LCY)")
                {
                    ApplicationArea = All;
                    Caption = 'Remaining Amount. (LCY)';
                    ToolTip = 'Specifies the net amount of in the local currency. The amount is calculated using the Remaining Quantity, Line Discount %, and Unit Price (LCY) fields. ';

                    trigger OnDrillDown()
                    var
                        Company: Record Company;
                        ConfPersonalizationMgt: Codeunit "Conf./Personalization Mgt.";
                        HyperLinkUrl: Text[500];
                    begin
                        Company.Get(CompanyName);
                        if Company."Evaluation Company" then
                            HyperLinkUrl := GetUrl(CLIENTTYPE::Web, CompanyName, OBJECTTYPE::Page, 574) +
                              '&' + ConfPersonalizationMgt.GetProfileUrlParameterForEvaluationCompany()
                              + StrSubstNo(FilterForRemAmtDrillDwnTxt, "Entry No.")
                        else
                            HyperLinkUrl := GetUrl(CLIENTTYPE::Web, CompanyName, OBJECTTYPE::Page, 574) + StrSubstNo(FilterForRemAmtDrillDwnTxt, "Entry No.");
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
        Vendor: Record Vendor;
    begin
        StyleTxt := SetStyle;
        Vendor.Get("Vendor No.");
        VendorName := Vendor.Name;
    end;

    trigger OnModifyRecord(): Boolean
    begin
        CODEUNIT.Run(CODEUNIT::"Vend. Entry-Edit", Rec);
        exit(false);
    end;

    trigger OnOpenPage()
    begin
        SetFilter("Due Date", '<%1', WorkDate);
        SetRange("Document Type", "Document Type"::Invoice);
        SetFilter("Remaining Amt. (LCY)", '<>0');
        Ascending := true;
    end;

    var
        StyleTxt: Text;
        VendorName: Text[250];
        FilterForRemAmtDrillDwnTxt: Label '&filter=''Detailed Vendor Ledg. Entry''.''Vendor Ledger Entry No.'' IS ''%1''', Comment = '%1 - Entry No. for Vendor ledger entry. ';

    procedure SetFilterForOverduePurInvoiceAmount()
    begin
        Reset;
        SetFilter("Due Date", '<%1', WorkDate);
        SetRange("Document Type", "Document Type"::Invoice);
        SetFilter("Remaining Amt. (LCY)", '<>0');
        Ascending := true;
        CurrPage.Update;
    end;

    procedure SetFilterForPurchDocsDueToday()
    begin
        Reset;
        SetRange(Open, true);
        SetFilter("Document Type", 'Invoice|Credit Memo');
        SetFilter("Due Date", '<=%1', WorkDate);
        Ascending := true;
        CurrPage.Update;
    end;

    procedure SetFilterForPurchInvoicesDueNextWeek()
    begin
        Reset;
        SetRange(Open, true);
        SetFilter("Document Type", 'Invoice|Credit Memo');
        SetFilter("Due Date", '%1..%2', CalcDate('<1D>', WorkDate), CalcDate('<1W>', WorkDate));
        Ascending := true;
        CurrPage.Update;
    end;
}

