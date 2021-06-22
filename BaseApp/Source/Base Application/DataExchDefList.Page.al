page 1211 "Data Exch Def List"
{
    AdditionalSearchTerms = 'file import,file export,data import,data export,data stream,transfer,ecommerce';
    ApplicationArea = Basic, Suite;
    Caption = 'Data Exchange Definitions';
    CardPageID = "Data Exch Def Card";
    PageType = List;
    PromotedActionCategories = 'New,Process,Report,Import/Export';
    SourceTable = "Data Exch. Def";
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Code"; Code)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a code that identifies the data exchange setup.';
                }
                field(Name; Name)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the data exchange definition.';
                }
                field(Type; Type)
                {
                    ApplicationArea = Basic, Suite;
                    ShowMandatory = true;
                    ToolTip = 'Specifies what type of exchange the data exchange definition is used for.';
                }
                field("Data Handling Codeunit"; "Data Handling Codeunit")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the codeunit that transfers data in and out of tables in Microsoft Dynamics 365.';
                }
                field("Validation Codeunit"; "Validation Codeunit")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the codeunit that is used to validate data against pre-defined business rules.';
                }
                field("Reading/Writing Codeunit"; "Reading/Writing Codeunit")
                {
                    ApplicationArea = Basic, Suite;
                    ShowMandatory = true;
                    ToolTip = 'Specifies the codeunit that processes imported data prior to mapping and exported data after mapping.';
                }
                field("Reading/Writing XMLport"; "Reading/Writing XMLport")
                {
                    ApplicationArea = Basic, Suite;
                    ShowMandatory = true;
                    ToolTip = 'Specifies the XMLport through which an imported data file or service enters prior to mapping and through which exported data exits when it is written to a data file or service after mapping.';
                }
                field("Ext. Data Handling Codeunit"; "Ext. Data Handling Codeunit")
                {
                    ApplicationArea = Basic, Suite;
                    ShowMandatory = true;
                    ToolTip = 'Specifies the codeunit that transfers external data in and out of the Data Exchange Framework.';
                }
                field("User Feedback Codeunit"; "User Feedback Codeunit")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the codeunit that does various clean-up after mapping, such as marks the lines as exported and deletes temporary records.';
                }
                field("Header Lines"; "Header Lines")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies how many header lines exist in the file. This ensures that the header data is not imported. This field is only relevant for import.';
                }
                field("Header Tag"; "Header Tag")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the text of the first column on the header line.';
                }
                field("Footer Tag"; "Footer Tag")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the text of the first column on the footer line. If a footer line exists in several places in the file, enter the text of the first column on the footer line to ensure that the footer data is not imported. This field is only relevant for import.';
                }
                field("Column Separator"; "Column Separator")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies how columns in the file are separated if the file is of type Variable Text.';
                }
                field("Custom Column Separator"; "Custom Column Separator")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies how columns in the file are separated if the file is of a custom type.';
                }
                field("File Encoding"; "File Encoding")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the encoding of the file to be imported. This field is only relevant for import.';
                }
                field("File Type"; "File Type")
                {
                    ApplicationArea = Basic, Suite;
                    ShowMandatory = true;
                    ToolTip = 'Specifies what type of file the data exchange definition is used for. You can select between three file types.';
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action("Import Data Exchange Definition")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Import Data Exchange Definition';
                Image = Import;
                Promoted = true;
                PromotedCategory = Category4;
                PromotedIsBig = true;
                ToolTip = 'Import a data exchange definition from a bank file that is located on your computer or network. The file type must match the value of the File Type field.';

                trigger OnAction()
                begin
                    XMLPORT.Run(XMLPORT::"Imp / Exp Data Exch Def & Map", false, true);
                end;
            }
            action("Export Data Exchange Definition")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Export Data Exchange Definition';
                Image = Export;
                Promoted = true;
                PromotedCategory = Category4;
                PromotedIsBig = true;
                ToolTip = 'Export the data exchange definition to a file on your computer or network. You can then upload the file to your electronic bank to process the related transfers.';

                trigger OnAction()
                var
                    DataExchDef: Record "Data Exch. Def";
                begin
                    CurrPage.SetSelectionFilter(DataExchDef);
                    XMLPORT.Run(XMLPORT::"Imp / Exp Data Exch Def & Map", false, false, DataExchDef);
                end;
            }
        }
    }
}

