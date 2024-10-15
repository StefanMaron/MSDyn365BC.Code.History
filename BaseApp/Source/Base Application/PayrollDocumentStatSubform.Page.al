page 17478 "Payroll Document Stat. Subform"
{
    Caption = 'Lines';
    Editable = false;
    PageType = ListPart;
    SourceTable = "Payroll Document Buffer";
    SourceTableTemporary = true;

    layout
    {
        area(content)
        {
            repeater(Control1210000)
            {
                ShowCaption = false;
                field("Element Code"; "Element Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code of the related payroll element for tax registration purposes.';
                }
                field("Payroll Posting Group"; "Payroll Posting Group")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Base Amount"; "Base Amount")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Tax Amount"; "Tax Amount")
                {
                    ApplicationArea = Basic, Suite;
                }
                field(GetDimensions; GetDimensionsList)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Dimensions';

                    trigger OnAssistEdit()
                    begin
                        DimMgt.ShowDimensionSet("Dimension Set ID", StrSubstNo('%1 - %2', "Element Code", "Payroll Posting Group"));
                    end;
                }
            }
        }
    }

    actions
    {
    }

    var
        DimMgt: Codeunit DimensionManagement;

    [Scope('OnPrem')]
    procedure SetPayrollDocBuffer(var NewPayrollDocBuffer: Record "Payroll Document Buffer")
    begin
        DeleteAll();
        if NewPayrollDocBuffer.FindSet then
            repeat
                Copy(NewPayrollDocBuffer);
                Insert;
            until NewPayrollDocBuffer.Next = 0;

        CurrPage.Update(false);
    end;

    [Scope('OnPrem')]
    procedure GetDimensionsList() Dimensions: Text[1024]
    var
        TempDimSetEntry: Record "Dimension Set Entry" temporary;
    begin
        DimMgt.GetDimensionSet(TempDimSetEntry, "Dimension Set ID");
        with TempDimSetEntry do
            if FindSet then
                repeat
                    if Dimensions = '' then
                        Dimensions := "Dimension Code" + '=' + "Dimension Value Code"
                    else
                        Dimensions :=
                          CopyStr(
                            Dimensions + ';' + "Dimension Code" + '=' + "Dimension Value Code",
                            1,
                            1024);
                until Next = 0;
    end;
}

