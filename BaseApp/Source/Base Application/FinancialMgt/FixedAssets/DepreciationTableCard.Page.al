page 5659 "Depreciation Table Card"
{
    Caption = 'Depreciation Table Card';
    PageType = ListPlus;
    SourceTable = "Depreciation Table Header";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("Code"; Code)
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies a code for the depreciation table.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies a description of the depreciation table.';
                }
                field("Period Length"; Rec."Period Length")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the length of period that each of the depreciation table lines will apply to.';
                }
                field("Total No. of Units"; Rec."Total No. of Units")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the total number of units the asset is expected to produce in its lifetime.';
                }
            }
            part(Control9; "Depreciation Table Lines")
            {
                ApplicationArea = FixedAssets;
                SubPageLink = "Depreciation Table Code" = FIELD(Code);
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
        area(processing)
        {
            group("F&unctions")
            {
                Caption = 'F&unctions';
                Image = "Action";
                action(CreateSumOfDigitsTable)
                {
                    ApplicationArea = FixedAssets;
                    Caption = 'Create Sum of Digits Table';
                    Image = NewSum;
                    ToolTip = 'Define a depreciation table for the Sum of Digits depreciation method. Example: If a fixed asset is depreciated over 4 years, then the depreciation for each year is calculated like this: Sum of Digits = 1 + 2 + 3 + 4 = 10. 1. year = 4/10 2. year = 3/10 3. year = 2/10 4. year = 1/10';

                    trigger OnAction()
                    var
                        CreateSumOfDigitsTable: Report "Create Sum of Digits Table";
                    begin
                        TestField(Code);
                        Clear(CreateSumOfDigitsTable);
                        CreateSumOfDigitsTable.SetTableCode(Code);
                        CreateSumOfDigitsTable.RunModal();
                        Clear(CreateSumOfDigitsTable);
                    end;
                }
            }
        }
    }
}

