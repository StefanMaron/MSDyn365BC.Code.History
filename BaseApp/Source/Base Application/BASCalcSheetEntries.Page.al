page 11606 "BAS Calc. Sheet Entries"
{
    Caption = 'BAS Calc. Sheet Entries';
    Editable = false;
    PageType = List;
    SourceTable = "BAS Calc. Sheet Entry";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field(Type; Type)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the type that is on the business activity statement (BAS) calculation sheet.';
                }
                field("Company Name"; "Company Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies that this is the name of the company connected to the relevant BAS.';
                    Visible = false;
                }
                field("BAS Document No."; "BAS Document No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies that this is the BAS Doc. No. that contained these entries.';
                    Visible = false;
                }
                field("BAS Version"; "BAS Version")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the BAS Version number that the transaction was included in, and operates in conjunction with the BAS Doc. No.';
                    Visible = false;
                }
                field("Field Label No."; "Field Label No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the field label from the XML file that is from the Australian Tax Office (ATO).';
                    Visible = false;
                }
                field("Amount Type"; "Amount Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount type that is on the business activity statement (BAS) calculation sheet.';
                }
                field(Amount; Amount)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Amount';
                    ToolTip = 'Specifies the entry amount that is on the business activity statement (BAS) calculation sheet.';
                }
                field("Entry No."; "Entry No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the entry number that is on the business activity statement (BAS) calculation sheet.';
                }
            }
        }
    }

    actions
    {
    }
}

