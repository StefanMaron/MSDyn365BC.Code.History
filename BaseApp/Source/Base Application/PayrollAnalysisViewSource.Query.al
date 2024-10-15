query 14960 "Payroll Analysis View Source"
{
    Caption = 'Payroll Analysis View Source';

    elements
    {
        dataitem(Payroll_Analysis_View; "Payroll Analysis View")
        {
            filter(PayrollAnalysisViewCode; "Code")
            {
            }
            dataitem(Payroll_Ledger_Entry; "Payroll Ledger Entry")
            {
                SqlJoinType = CrossJoin;
                DataItemTableFilter = "Element Code" = FILTER(<> '');
                filter(EntryNo; "Entry No.")
                {
                }
                column(ElementCode; "Element Code")
                {
                }
                column(EmployeeNo; "Employee No.")
                {
                }
                column(PostingDate; "Posting Date")
                {
                }
                column(DimensionSetID; "Dimension Set ID")
                {
                }
                column(UsePFAccumSystem; "Use PF Accum. System")
                {
                }
                column(CalcGroup; "Calc Group")
                {
                }
                column(PayrollAmount; "Payroll Amount")
                {
                    Method = Sum;
                }
                column(TaxableAmount; "Taxable Amount")
                {
                    Method = Sum;
                }
                dataitem(DimSet1; "Dimension Set Entry")
                {
                    DataItemLink = "Dimension Set ID" = Payroll_Ledger_Entry."Dimension Set ID", "Dimension Code" = Payroll_Analysis_View."Dimension 1 Code";
                    column(DimVal1; "Dimension Value Code")
                    {
                    }
                    dataitem(DimSet2; "Dimension Set Entry")
                    {
                        DataItemLink = "Dimension Set ID" = Payroll_Ledger_Entry."Dimension Set ID", "Dimension Code" = Payroll_Analysis_View."Dimension 2 Code";
                        column(DimVal2; "Dimension Value Code")
                        {
                        }
                        dataitem(DimSet3; "Dimension Set Entry")
                        {
                            DataItemLink = "Dimension Set ID" = Payroll_Ledger_Entry."Dimension Set ID", "Dimension Code" = Payroll_Analysis_View."Dimension 3 Code";
                            column(DimVal3; "Dimension Value Code")
                            {
                            }
                            dataitem(DimSet4; "Dimension Set Entry")
                            {
                                DataItemLink = "Dimension Set ID" = Payroll_Ledger_Entry."Dimension Set ID", "Dimension Code" = Payroll_Analysis_View."Dimension 4 Code";
                                column(DimVal4; "Dimension Value Code")
                                {
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

