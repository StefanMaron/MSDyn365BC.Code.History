page 1158 "Cash Account Balances"
{
    Caption = 'Cash Account Balances';
    DeleteAllowed = false;
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = ListPart;
    SourceTable = "G/L Account";

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("No."; Rec."No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
                }
                field(Name; Rec.Name)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the name of the cash account.';
                }
                field(Balance; Balance)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the balance of the cash account.';

                    trigger OnDrillDown()
                    var
                        Company: Record Company;
                        ConfPersonalizationMgt: Codeunit "Conf./Personalization Mgt.";
                        HyperLinkUrl: Text[500];
                    begin
                        Company.Get(CompanyName);
                        if Company."Evaluation Company" then
                            HyperLinkUrl := GetUrl(CLIENTTYPE::Web, CompanyName, OBJECTTYPE::Page, 20) +
                              '&' + ConfPersonalizationMgt.GetProfileUrlParameterForEvaluationCompany() +
                              StrSubstNo(FilterForBalanceDrillDwnTxt, "No.")

                        else
                            HyperLinkUrl := GetUrl(CLIENTTYPE::Web, CompanyName, OBJECTTYPE::Page, 20) + StrSubstNo(FilterForBalanceDrillDwnTxt, "No.");
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

    trigger OnOpenPage()
    begin
        SetRange("Account Category", "Account Category"::Assets);
        SetRange("Account Type", "Account Type"::Posting);
        SetRange("Account Subcategory Entry No.", 3);
    end;

    var
        FilterForBalanceDrillDwnTxt: Label '&filter=''G/L Entry''.''G/L Account No.'' IS ''%1''', Comment = '%1 - G/L Account record No. which data type of CODE.';
}

