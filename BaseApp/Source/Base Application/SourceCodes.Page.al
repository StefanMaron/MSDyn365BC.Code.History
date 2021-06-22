page 257 "Source Codes"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Source Codes';
    PageType = List;
    SourceTable = "Source Code";
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Code"; Code)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the source code.';
                }
                field(Description; Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a description of what the code stands for.';
                }
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
        area(navigation)
        {
            group("&Source")
            {
                Caption = '&Source';
                Image = CodesList;
                action("G/L Registers")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'G/L Registers';
                    Image = GLRegisters;
                    RunObject = Page "G/L Registers";
                    RunPageLink = "Source Code" = FIELD(Code);
                    RunPageView = SORTING("Source Code");
                    ToolTip = 'View posted G/L entries.';
                }
                action("Item Registers")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Item Registers';
                    Image = ItemRegisters;
                    RunObject = Page "Item Registers";
                    RunPageLink = "Source Code" = FIELD(Code);
                    RunPageView = SORTING("Source Code");
                    ToolTip = 'View posted item entries.';
                }
                action("Resource Registers")
                {
                    ApplicationArea = Jobs;
                    Caption = 'Resource Registers';
                    Image = ResourceRegisters;
                    RunObject = Page "Resource Registers";
                    RunPageLink = "Source Code" = FIELD(Code);
                    RunPageView = SORTING("Source Code");
                    ToolTip = 'View a list of all the resource registers. Every time a resource entry is posted, a register is created. Every register shows the first and last entry numbers of its entries. You can use the information in a resource register to document when entries were posted.';
                }
                action("Job Registers")
                {
                    ApplicationArea = Jobs;
                    Caption = 'Job Registers';
                    Image = JobRegisters;
                    RunObject = Page "Job Registers";
                    RunPageLink = "Source Code" = FIELD(Code);
                    RunPageView = SORTING("Source Code");
                    ToolTip = 'Open the related job registers.';
                }
                action("FA Registers")
                {
                    ApplicationArea = FixedAssets;
                    Caption = 'FA Registers';
                    Image = FARegisters;
                    RunObject = Page "FA Registers";
                    RunPageLink = "Source Code" = FIELD(Code);
                    RunPageView = SORTING("Source Code");
                    ToolTip = 'View the fixed asset registers. Every register shows the first and last entry numbers of its entries. An FA register is created when you post a transaction that results in one or more FA entries.';
                }
                action("I&nsurance Registers")
                {
                    ApplicationArea = FixedAssets;
                    Caption = 'I&nsurance Registers';
                    Image = InsuranceRegisters;
                    RunObject = Page "Insurance Registers";
                    RunPageLink = "Source Code" = FIELD(Code);
                    RunPageView = SORTING("Source Code");
                    ToolTip = 'View posted insurance entries.';
                }
                action("Warehouse Registers")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Warehouse Registers';
                    Image = WarehouseRegisters;
                    RunObject = Page "Warehouse Registers";
                    RunPageLink = "Source Code" = FIELD(Code);
                    RunPageView = SORTING("Source Code");
                    ToolTip = 'View all warehouse entries per registration date.';
                }
            }
        }
    }
}

