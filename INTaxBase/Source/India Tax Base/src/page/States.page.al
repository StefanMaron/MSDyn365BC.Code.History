page 18547 "States"
{
    PageType = List;
    ApplicationArea = Basic, Suite;
    UsageCategory = Lists;
    SourceTable = State;

    layout
    {
        area(Content)
        {
            repeater(General)
            {
                field(Code; Code)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the state codes as per the Income Tax Act 1961';
                }
                field(Description; Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the description of state codes';
                }
                field("State Code for eTDS/TCS"; "State Code for eTDS/TCS")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the numeric code for state which is mandatory if deductor type is State Govt. (code S), Statutory body - State Govt. (code E), Autonomous body - State Govt. code H) and Local Authority - State Govt. (code N).';
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(EditInExcel)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Edit in Excel';
                Image = Excel;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                PromotedOnly = true;
                ToolTip = 'Send the data in the  page to an Excel file for analysis or editing';

                trigger OnAction()
                var
                    ODataUtility: Codeunit ODataUtility;
                    StateCodeLbl: Label 'Code eq %1', Comment = '%1= State Code';
                begin
                    ODataUtility.EditWorksheetInExcel(
                        'States',
                        CurrPage.ObjectId(false),
                        StrSubstNo(StateCodeLbl, Code));
                end;
            }
        }
    }
}