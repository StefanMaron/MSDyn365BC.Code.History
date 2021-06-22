page 5649 "Total Value Insured"
{
    Caption = 'Total Value Insured';
    Editable = false;
    PageType = Document;
    SourceTable = "Fixed Asset";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("No."; "No.")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
                }
                field(Description; Description)
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies a description of the fixed asset.';
                }
                field("FASetup.""Insurance Depr. Book"""; FASetup."Insurance Depr. Book")
                {
                    ApplicationArea = FixedAssets;
                    Caption = 'Insurance Depr. Book';
                    ToolTip = 'Specifies the depreciation book code that is specified in the Fixed Asset Setup window.';
                }
                field("FADeprBook.""Acquisition Cost"""; FADeprBook."Acquisition Cost")
                {
                    ApplicationArea = FixedAssets;
                    Caption = 'Acquisition Cost';
                    ToolTip = 'Specifies the total percentage of acquisition cost that can be allocated when acquisition cost is posted.';
                }
            }
            part(TotalValue; "Total Value Insured Subform")
            {
                ApplicationArea = FixedAssets;
            }
        }
        area(factboxes)
        {
            systempart(Control1900383207; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(Control1905767507; Notes)
            {
                ApplicationArea = Notes;
                Visible = false;
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetCurrRecord()
    begin
        CurrPage.TotalValue.PAGE.CreateTotalValue("No.");
        FASetup.Get();
        FADeprBook.Init();
        if FASetup."Insurance Depr. Book" <> '' then
            if FADeprBook.Get("No.", FASetup."Insurance Depr. Book") then
                FADeprBook.CalcFields("Acquisition Cost");
    end;

    var
        FASetup: Record "FA Setup";
        FADeprBook: Record "FA Depreciation Book";
}

