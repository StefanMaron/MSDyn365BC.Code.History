namespace Microsoft.Manufacturing.StandardCost;

report 5853 "Copy Standard Cost Worksheet"
{
    Caption = 'Copy Standard Cost Worksheet';
    ProcessingOnly = true;

    dataset
    {
        dataitem("Standard Cost Worksheet"; "Standard Cost Worksheet")
        {
            DataItemTableView = sorting("Standard Cost Worksheet Name", Type, "No.");

            trigger OnAfterGetRecord()
            begin
                InsertStdCostWksh();
                if CurrentDateTime - WindowUpdateDateTime >= 750 then begin
                    Window.Update(1, Type);
                    Window.Update(2, "No.");

                    WindowUpdateDateTime := CurrentDateTime;
                end;
            end;

            trigger OnPostDataItem()
            begin
                Window.Close();

                if not NoMessage then
                    Message(Text010);
            end;

            trigger OnPreDataItem()
            begin
                FromStdCostWkshName.Get(FromStdCostWkshName.Name);
                SetFilter("Standard Cost Worksheet Name", FromStdCostWkshName.Name);

                WindowUpdateDateTime := CurrentDateTime;
                Window.Open(Text007 + Text008 + Text009);
            end;
        }
    }

    requestpage
    {
        SaveValues = true;

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    group("Copy from")
                    {
                        Caption = 'Copy from';
                        field("FromStdCostWkshName.Name"; FromStdCostWkshName.Name)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Standard Cost Worksheet Name';
                            TableRelation = "Standard Cost Worksheet Name";
                            ToolTip = 'Specifies the name of the worksheet.';
                        }
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

    trigger OnPreReport()
    var
        StdCostWkshName: Record "Standard Cost Worksheet Name";
    begin
        if ToStdCostWkshName = '' then
            Error(Text003);
        StdCostWkshName.Get(ToStdCostWkshName);

        if FromStdCostWkshName.Name = '' then
            Error(Text004);
        FromStdCostWkshName.Get(FromStdCostWkshName.Name);

        ToStdCostWksh.LockTable();
    end;

    var
        ToStdCostWksh: Record "Standard Cost Worksheet";
        FromStdCostWkshName: Record "Standard Cost Worksheet Name";
        Window: Dialog;
        ToStdCostWkshName: Code[10];
        NoMessage: Boolean;
        WindowUpdateDateTime: DateTime;

        Text003: Label 'You must specify a worksheet name to copy to.';
        Text004: Label 'You must specify a worksheet name to copy from.';
        Text007: Label 'Copying worksheet...\\';
        Text008: Label 'Type               #1##########\';
        Text009: Label 'No.             #2##########\';
        Text010: Label 'The worksheet has been successfully copied.';

    local procedure InsertStdCostWksh()
    begin
        with ToStdCostWksh do begin
            ToStdCostWksh := "Standard Cost Worksheet";
            "Standard Cost Worksheet Name" := ToStdCostWkshName;
            if not Insert(true) then
                Modify(true);
        end;
    end;

    procedure SetCopyToWksh(ToStdCostWkshName2: Code[10])
    begin
        ToStdCostWkshName := ToStdCostWkshName2;
    end;

    procedure Initialize(FromStdCostWkshName2: Code[10]; ToStdCostWkshName2: Code[10]; NoMessage2: Boolean)
    begin
        FromStdCostWkshName.Name := FromStdCostWkshName2;
        ToStdCostWkshName := ToStdCostWkshName2;
        NoMessage := NoMessage2;
    end;
}

