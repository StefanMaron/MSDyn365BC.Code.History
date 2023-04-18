report 5884 "Calc. Phys. Invt. Order Count"
{
    Caption = 'Calc. Phys. Invt. Order Count';
    ProcessingOnly = true;

    dataset
    {
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
                    field(CalcQtyExpected; CalcQtyExpected)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Calculate Qty. Expected';
                        ToolTip = 'Specifies if you want the program to calculate and insert the contents of the field quantity expected for new created physical inventory order lines.';
                    }
                    field(ZeroQty; ZeroQty)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Items Not on Inventory';
                        ToolTip = 'Specifies if journal lines should be created for items that are not on inventory, that is, items where the value in the Qty. (Calculated) field is 0.';
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
    begin
        OKPressed := true;
    end;

    var
        ZeroQty: Boolean;
        CalcQtyExpected: Boolean;
        OKPressed: Boolean;

    procedure GetRequest(var ZeroQty2: Boolean; var CalcQtyExpected2: Boolean): Boolean
    begin
        ZeroQty2 := ZeroQty;
        CalcQtyExpected2 := CalcQtyExpected;
        exit(OKPressed);
    end;
}

