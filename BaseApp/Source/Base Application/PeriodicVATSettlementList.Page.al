page 12121 "Periodic VAT Settlement List"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Periodic VAT Settlement List';
    CardPageID = "Periodic VAT Settlement Card";
    Editable = true;
    PageType = List;
    SourceTable = "Periodic Settlement VAT Entry";
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                Editable = false;
                ShowCaption = false;
                field("VAT Period"; "VAT Period")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the period of time that defines the VAT period.';
                }
                field("VAT Settlement"; "VAT Settlement")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the net VAT amount that is transferred to the VAT settlement account.';
                }
                field("Add-Curr. VAT Settlement"; "Add-Curr. VAT Settlement")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the net VAT amount that is transferred to the VAT settlement account.';
                    Visible = false;
                }
                field("Prior Period Input VAT"; "Prior Period Input VAT")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount of input VAT from purchases during the previous period.';
                    Visible = true;
                }
                field("Prior Period Output VAT"; "Prior Period Output VAT")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount of output VAT from sales during the prior period.';
                }
                field("Add Curr. Prior Per. Inp. VAT"; "Add Curr. Prior Per. Inp. VAT")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount of input VAT from purchases during the previous period.';
                    Visible = false;
                }
                field("Add Curr. Prior Per. Out VAT"; "Add Curr. Prior Per. Out VAT")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount of output VAT from sales during the prior period.';
                    Visible = false;
                }
                field("Paid Amount"; "Paid Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount of VAT that is paid to the tax authority.';
                }
                field("Advanced Amount"; "Advanced Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount of VAT tax that is paid in advance to offset future VAT liabilities.';
                }
                field("Add-Curr. Paid. Amount"; "Add-Curr. Paid. Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount of VAT that is paid to the tax authority.';
                    Visible = false;
                }
                field("Add-Curr. Advanced Amount"; "Add-Curr. Advanced Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount of VAT tax that is paid in advance to offset future VAT liabilities.';
                    Visible = false;
                }
                field("Bank Code"; "Bank Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the bank code that is assigned to the bank account that is used for the VAT settlement transaction.';
                }
                field("Paid Date"; "Paid Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date that the VAT settlement transaction is posted and sent to the tax authority.';
                }
                field(Description; Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a description for the periodic settlement VAT entry.';
                }
                field("Prior Year Input VAT"; "Prior Year Input VAT")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount of input VAT from purchases during the previous year.';
                }
                field("Prior Year Output VAT"; "Prior Year Output VAT")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount of output VAT from sales during the prior year.';
                }
                field("VAT Period Closed"; "VAT Period Closed")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the VAT period has been closed.';
                }
            }
        }
    }

    actions
    {
    }
}

