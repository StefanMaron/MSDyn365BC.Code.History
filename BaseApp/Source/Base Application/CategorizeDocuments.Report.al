report 7000095 "Categorize Documents"
{
    Caption = 'Categorize Documents';
    Permissions = TableData "Cartera Doc." = m;
    ProcessingOnly = true;

    dataset
    {
        dataitem("Cartera Doc."; "Cartera Doc.")
        {
            DataItemTableView = SORTING(Type, "Entry No.");

            trigger OnPreDataItem()
            begin
                ModifyAll("Category Code", CategoryCode);
                CurrReport.Break();
            end;
        }
    }

    requestpage
    {

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(CategoryCode; CategoryCode)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Category Code';
                        TableRelation = "Category Code";
                        ToolTip = 'Specifies the category.';
                    }
                }
            }
        }

        actions
        {
        }
    }

    labels
    {
    }

    var
        CategoryCode: Code[10];
}

