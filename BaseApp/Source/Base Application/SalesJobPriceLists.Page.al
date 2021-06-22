page 7019 "Sales Job Price Lists"
{
    Caption = 'Sales Job Price Lists';
    CardPageID = "Sales Price List";
    Editable = false;
    PageType = List;
    PromotedActionCategories = 'New,Process,Report';
    QueryCategory = 'Sales Job Price Lists';
    RefreshOnActivate = true;
    SourceTable = "Price List Header";
    SourceTableView = WHERE("Source Group" = CONST(Job), "Price Type" = CONST(Sale));
    ApplicationArea = Jobs;
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field(Code; Rec.Code)
                {
                    ApplicationArea = Jobs;
                    Visible = false;
                    Caption = 'Code';
                    ToolTip = 'Specifies the unique identifier of the price list.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Jobs;
                    Caption = 'Description';
                    ToolTip = 'Specifies the description of the price list.';
                }
                field(Status; Rec.Status)
                {
                    ApplicationArea = Jobs;
                    Caption = 'Status';
                    ToolTip = 'Specifies whether the price list is in Draft status and can be edited, Inactive and cannot be edited or used, or Active and used for price calculations.';
                }
                field("Allow Updating Defaults"; Rec."Allow Updating Defaults")
                {
                    ApplicationArea = Jobs;
                    Caption = 'Multi-Type Price List';
                    ToolTip = 'Specifies whether users can change the values in the fields on the price list line that contain default values from the header.';
                }
                field(Defines; Rec."Amount Type")
                {
                    ApplicationArea = Jobs;
                    Caption = 'Defines';
                    ToolTip = 'Specifies whether the price list defines prices, discounts, or both.';
                }
                field("Currency Code"; CurrRec."Currency Code")
                {
                    ApplicationArea = Jobs;
                    Caption = 'Currency';
                    ToolTip = 'Specifies the currency that is used on the price list.';
                }
                field(SourceGroup; Rec."Source Group")
                {
                    ApplicationArea = Jobs;
                    Caption = 'Applies-to Group';
                    Visible = false;
                    ToolTip = 'Specifies whether the prices come from groups of customers, vendors or jobs.';
                }
                field(SourceType; CurrRec."Source Type")
                {
                    ApplicationArea = Jobs;
                    Caption = 'Applies-to Type';
                    ToolTip = 'Specifies the source type of the price list.';
                }
                field(SourceNo; CurrRec."Source No.")
                {
                    ApplicationArea = Jobs;
                    Caption = 'Applies-to No.';
                    ToolTip = 'Specifies the unique identifier of the source of the price on the price list line.';
                }
                field(ParentSourceNo; CurrRec."Parent Source No.")
                {
                    ApplicationArea = Jobs;
                    Caption = 'Applies-to Job No.';
                    ToolTip = 'Specifies the job that is the source of the price on the price list line.';
                }
                field("Starting Date"; CurrRec."Starting Date")
                {
                    ApplicationArea = Jobs;
                    Caption = 'Starting Date';
                    ToolTip = 'Specifies the date from which the price is valid.';
                }
                field("Ending Date"; CurrRec."Ending Date")
                {
                    ApplicationArea = Jobs;
                    Caption = 'Ending Date';
                    ToolTip = 'Specifies the date when the sales price agreement ends.';
                }
            }
        }
    }

    trigger OnInit()
    var
        PriceCalculationMgt: Codeunit "Price Calculation Mgt.";
    begin
        PriceCalculationMgt.TestIsEnabled();
    end;

    trigger OnAfterGetRecord()
    begin
        CurrRec := Rec;
        CurrRec.BlankDefaults();
    end;

    trigger OnAfterGetCurrRecord()
    begin
        CurrRec := Rec;
        CurrRec.BlankDefaults();
    end;

    var
        CurrRec: Record "Price List Header";

    procedure SetRecordFilter(var PriceListHeader: Record "Price List Header")
    begin
        Rec.FilterGroup := 2;
        Rec.CopyFilters(PriceListHeader);
        Rec.SetRange("Source Group", Rec."Source Group"::Job);
        Rec.SetRange("Price Type", Rec."Price Type"::Sale);
        Rec.FilterGroup := 0;
    end;

    procedure SetSource(PriceSourceList: Codeunit "Price Source List"; AmountType: Enum "Price Amount Type")
    var
        PriceUXManagement: Codeunit "Price UX Management";
    begin
        PriceUXManagement.SetPriceListsFilters(Rec, PriceSourceList, AmountType);
    end;
}
