namespace Microsoft.Projects.Project.Job;

page 1025 "Job Statistics"
{
    Caption = 'Job Statistics';
    Editable = false;
    LinksAllowed = false;
    PageType = Card;
    SourceTable = Job;

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                fixed(Control1903895301)
                {
                    ShowCaption = false;
                    group(Resource)
                    {
                        Caption = 'Resource';
                        field(Text000; '')
                        {
                            ApplicationArea = Jobs;
                            Caption = 'Price LCY';
                            ToolTip = 'Specifies the price amounts, expressed in the local currency.';
                        }
                        field(SchedulePriceLCY; PL[1])
                        {
                            ApplicationArea = Jobs;
                            Caption = 'Budget';
                            Editable = false;
                            ToolTip = 'Specifies values for budgeted jobs.';

                            trigger OnDrillDown()
                            begin
                                JobCalcStatistics.ShowPlanningLine(1, true);
                            end;
                        }
                        field(UsagePriceLCY; PL[5])
                        {
                            ApplicationArea = Jobs;
                            Caption = 'Usage';
                            Editable = false;
                            ToolTip = 'Specifies values for job usage.';

                            trigger OnDrillDown()
                            begin
                                JobCalcStatistics.ShowLedgEntry(1, true);
                            end;
                        }
                        field(ContractPriceLCY; PL[9])
                        {
                            ApplicationArea = Jobs;
                            Caption = 'Billable';
                            Editable = false;
                            ToolTip = 'Specifies the billable amounts.';

                            trigger OnDrillDown()
                            begin
                                JobCalcStatistics.ShowPlanningLine(1, false);
                            end;
                        }
                        field(InvoicedPriceLCY; PL[13])
                        {
                            ApplicationArea = Jobs;
                            Caption = 'Invoiced';
                            Editable = false;
                            ToolTip = 'Specifies values for invoiced jobs.';

                            trigger OnDrillDown()
                            begin
                                JobCalcStatistics.ShowLedgEntry(1, false);
                            end;
                        }
                        field("Cost LCY"; '')
                        {
                            ApplicationArea = Jobs;
                            Caption = 'Cost LCY';
                            ToolTip = 'Specifies the job cost amount, expressed in the local currency.';
                        }
                        field(ScheduleCostLCY; CL[1])
                        {
                            ApplicationArea = Jobs;
                            Caption = 'Budget';
                            Editable = false;
                            ToolTip = 'Specifies values for budgeted jobs.';

                            trigger OnDrillDown()
                            begin
                                JobCalcStatistics.ShowPlanningLine(1, true);
                            end;
                        }
                        field(UsageCostLCY; CL[5])
                        {
                            ApplicationArea = Jobs;
                            Caption = 'Usage';
                            Editable = false;
                            ToolTip = 'Specifies values for job usage.';

                            trigger OnDrillDown()
                            begin
                                JobCalcStatistics.ShowLedgEntry(1, true);
                            end;
                        }
                        field(ContractCostLCY; CL[9])
                        {
                            ApplicationArea = Jobs;
                            Caption = 'Billable';
                            Editable = false;
                            ToolTip = 'Specifies the billable amounts.';

                            trigger OnDrillDown()
                            begin
                                JobCalcStatistics.ShowPlanningLine(1, false);
                            end;
                        }
                        field(InvoicedCostLCY; CL[13])
                        {
                            ApplicationArea = Jobs;
                            Caption = 'Invoiced';
                            Editable = false;
                            ToolTip = 'Specifies values for invoiced jobs.';

                            trigger OnDrillDown()
                            begin
                                JobCalcStatistics.ShowLedgEntry(1, false);
                            end;
                        }
                        field("Profit LCY"; '')
                        {
                            ApplicationArea = Jobs;
                            Caption = 'Profit LCY';
                            ToolTip = 'Specifies the profit amounts, expressed in the local currency.';
                        }
                        field(ScheduleProfitLCY; PL[1] - CL[1])
                        {
                            ApplicationArea = Jobs;
                            Caption = 'Budget';
                            Editable = false;
                            ToolTip = 'Specifies values for budgeted jobs.';

                            trigger OnDrillDown()
                            begin
                                JobCalcStatistics.ShowPlanningLine(1, true);
                            end;
                        }
                        field(UsageProfitLCY; PL[5] - CL[5])
                        {
                            ApplicationArea = Jobs;
                            Caption = 'Usage';
                            Editable = false;
                            ToolTip = 'Specifies values for job usage.';

                            trigger OnDrillDown()
                            begin
                                JobCalcStatistics.ShowLedgEntry(1, true);
                            end;
                        }
                        field(ContractProfitLCY; PL[9] - CL[9])
                        {
                            ApplicationArea = Jobs;
                            Caption = 'Billable';
                            Editable = false;
                            ToolTip = 'Specifies the billable amounts.';

                            trigger OnDrillDown()
                            begin
                                JobCalcStatistics.ShowPlanningLine(1, false);
                            end;
                        }
                        field(InvoicedProfitLCY; PL[13] - CL[13])
                        {
                            ApplicationArea = Jobs;
                            Caption = 'Invoiced';
                            Editable = false;
                            ToolTip = 'Specifies values for invoiced jobs.';

                            trigger OnDrillDown()
                            begin
                                JobCalcStatistics.ShowLedgEntry(1, false);
                            end;
                        }
                    }
                    group(Item)
                    {
                        Caption = 'Item';
                        field(Placeholder2; Text000)
                        {
                            ApplicationArea = Jobs;
                            Visible = false;
                        }
                        field(SchedulePriceLCYItem; PL[2])
                        {
                            ApplicationArea = Jobs;
                            Caption = 'Budget Price LCY (Item)';
                            Editable = false;
                            ToolTip = 'Specifies budgeted prices for the job that are related to items, expressed in the local currency.';

                            trigger OnDrillDown()
                            begin
                                JobCalcStatistics.ShowPlanningLine(2, true);
                            end;
                        }
                        field(UsagePriceLCYItem; PL[6])
                        {
                            ApplicationArea = Jobs;
                            Caption = 'Usage Price LCY (Item)';
                            Editable = false;
                            ToolTip = 'Specifies usage prices for the job that are related to items, expressed in the local currency.';

                            trigger OnDrillDown()
                            begin
                                JobCalcStatistics.ShowLedgEntry(2, true);
                            end;
                        }
                        field(ContractPriceLCYItem; PL[10])
                        {
                            ApplicationArea = Jobs;
                            Caption = 'Billable Price LCY (Item)';
                            Editable = false;
                            ToolTip = 'Specifies billable prices for the job that are related to items, expressed in the local currency.';

                            trigger OnDrillDown()
                            begin
                                JobCalcStatistics.ShowPlanningLine(2, false);
                            end;
                        }
                        field(InvoicedPriceLCYItem; PL[14])
                        {
                            ApplicationArea = Jobs;
                            Caption = 'Invoiced Price LCY (Item)';
                            Editable = false;
                            ToolTip = 'Specifies invoiced prices for the job that are related to items, expressed in the local currency.';

                            trigger OnDrillDown()
                            begin
                                JobCalcStatistics.ShowLedgEntry(2, false);
                            end;
                        }
                        field(Placeholder3; Text000)
                        {
                            ApplicationArea = Jobs;
                            Visible = false;
                        }
                        field(ScheduleCostLCYItem; CL[2])
                        {
                            ApplicationArea = Jobs;
                            Caption = 'Budget Cost LCY (Item)';
                            Editable = false;
                            ToolTip = 'Specifies budgeted costs for the job that are related to items, expressed in the local currency.';

                            trigger OnDrillDown()
                            begin
                                JobCalcStatistics.ShowPlanningLine(2, true);
                            end;
                        }
                        field(UsageCostLCYItem; CL[6])
                        {
                            ApplicationArea = Jobs;
                            Caption = 'Usage Cost LCY (Item)';
                            Editable = false;
                            ToolTip = 'Specifies usage costs for the job that are related to items, expressed in the local currency.';

                            trigger OnDrillDown()
                            begin
                                JobCalcStatistics.ShowLedgEntry(2, true);
                            end;
                        }
                        field(ContractCostLCYItem; CL[10])
                        {
                            ApplicationArea = Jobs;
                            Caption = 'Billable Cost LCY (Item)';
                            Editable = false;
                            ToolTip = 'Specifies billable costs for the job that are related to items, expressed in the local currency.';

                            trigger OnDrillDown()
                            begin
                                JobCalcStatistics.ShowPlanningLine(2, false);
                            end;
                        }
                        field(InvoicedCostLCYItem; CL[14])
                        {
                            ApplicationArea = Jobs;
                            Caption = 'Invoiced Cost LCY (Item)';
                            Editable = false;
                            ToolTip = 'Specifies invoiced costs for the job that are related to items, expressed in the local currency.';

                            trigger OnDrillDown()
                            begin
                                JobCalcStatistics.ShowLedgEntry(2, false);
                            end;
                        }
                        field(Placeholder4; Text000)
                        {
                            ApplicationArea = Jobs;
                            Visible = false;
                        }
                        field(ScheduleProfitLCYItem; PL[2] - CL[2])
                        {
                            ApplicationArea = Jobs;
                            Caption = 'Budget Profit LCY (Item)';
                            Editable = false;
                            ToolTip = 'Specifies budgeted profits for the job that are related to items, expressed in the local currency.';

                            trigger OnDrillDown()
                            begin
                                JobCalcStatistics.ShowPlanningLine(2, true);
                            end;
                        }
                        field(UsageProfitLCYItem; PL[6] - CL[6])
                        {
                            ApplicationArea = Jobs;
                            Caption = 'Usage Profit LCY (Item)';
                            Editable = false;
                            ToolTip = 'Specifies usage profits for the job that are related to items, expressed in the local currency.';

                            trigger OnDrillDown()
                            begin
                                JobCalcStatistics.ShowLedgEntry(2, true);
                            end;
                        }
                        field(ContractProfitLCYItem; PL[10] - CL[10])
                        {
                            ApplicationArea = Jobs;
                            Caption = 'Billable Profit LCY (Item)';
                            Editable = false;
                            ToolTip = 'Specifies billable profits for the job that are related to items, expressed in the local currency.';

                            trigger OnDrillDown()
                            begin
                                JobCalcStatistics.ShowPlanningLine(2, false);
                            end;
                        }
                        field(InvoicedProfitLCYItem; PL[14] - CL[14])
                        {
                            ApplicationArea = Jobs;
                            Caption = 'Invoiced Profit LCY (Item)';
                            Editable = false;
                            ToolTip = 'Specifies invoiced profits for the job that are related to items, expressed in the local currency.';

                            trigger OnDrillDown()
                            begin
                                JobCalcStatistics.ShowLedgEntry(2, false);
                            end;
                        }
                    }
                    group("G/L Account")
                    {
                        Caption = 'G/L Account';
                        field(Placeholder6; Text000)
                        {
                            ApplicationArea = Jobs;
                            Visible = false;
                        }
                        field(SchedulePriceLCYGLAcc; PL[3])
                        {
                            ApplicationArea = Jobs;
                            Caption = 'Budget Price LCY (G/L Acc.)';
                            Editable = false;
                            ToolTip = 'Specifies budgeted prices for the job that are related to G/L accounts, expressed in the local currency.';

                            trigger OnDrillDown()
                            begin
                                JobCalcStatistics.ShowPlanningLine(3, true);
                            end;
                        }
                        field(UsagePriceLCYGLAcc; PL[7])
                        {
                            ApplicationArea = Jobs;
                            Caption = 'Usage Price LCY (G/L Acc.)';
                            Editable = false;
                            ToolTip = 'Specifies usage prices for the job that are related to G/L accounts, expressed in the local currency.';

                            trigger OnDrillDown()
                            begin
                                JobCalcStatistics.ShowLedgEntry(3, true);
                            end;
                        }
                        field(ContractPriceLCYGLAcc; PL[11])
                        {
                            ApplicationArea = Jobs;
                            Caption = 'Billable Price LCY (G/L Acc.)';
                            Editable = false;
                            ToolTip = 'Specifies billable prices for the job that are related to G/L accounts, expressed in the local currency.';

                            trigger OnDrillDown()
                            begin
                                JobCalcStatistics.ShowPlanningLine(3, false);
                            end;
                        }
                        field(InvoicedPriceLCYGLAcc; PL[15])
                        {
                            ApplicationArea = Jobs;
                            Caption = 'Invoiced Price LCY (G/L Acc.)';
                            Editable = false;
                            ToolTip = 'Specifies invoiced prices for the job that are related to G/L accounts, expressed in the local currency.';

                            trigger OnDrillDown()
                            begin
                                JobCalcStatistics.ShowLedgEntry(3, false);
                            end;
                        }
                        field(Placeholder7; Text000)
                        {
                            ApplicationArea = Jobs;
                            Visible = false;
                        }
                        field(ScheduleCostLCYGLAcc; CL[3])
                        {
                            ApplicationArea = Jobs;
                            Caption = 'Budget Cost LCY (G/L Acc.)';
                            Editable = false;
                            ToolTip = 'Specifies budgeted costs for the job that are related to G/L accounts, expressed in the local currency.';

                            trigger OnDrillDown()
                            begin
                                JobCalcStatistics.ShowPlanningLine(3, true);
                            end;
                        }
                        field(UsageCostLCYGLAcc; CL[7])
                        {
                            ApplicationArea = Jobs;
                            Caption = 'Usage Cost LCY (G/L Acc.)';
                            Editable = false;
                            ToolTip = 'Specifies usage costs for the job that are related to G/L accounts, expressed in the local currency.';

                            trigger OnDrillDown()
                            begin
                                JobCalcStatistics.ShowLedgEntry(3, true);
                            end;
                        }
                        field(ContractCostLCYGLAcc; CL[11])
                        {
                            ApplicationArea = Jobs;
                            Caption = 'Billable Cost LCY (G/L Acc.)';
                            Editable = false;
                            ToolTip = 'Specifies billable costs for the job that are related to G/L accounts, expressed in the local currency.';

                            trigger OnDrillDown()
                            begin
                                JobCalcStatistics.ShowPlanningLine(3, false);
                            end;
                        }
                        field(InvoicedCostLCYGLAcc; CL[15])
                        {
                            ApplicationArea = Jobs;
                            Caption = 'Invoiced Cost LCY (G/L Acc.)';
                            Editable = false;
                            ToolTip = 'Specifies invoiced costs for the job that are related to G/L accounts, expressed in the local currency.';

                            trigger OnDrillDown()
                            begin
                                JobCalcStatistics.ShowLedgEntry(3, false);
                            end;
                        }
                        field(Placeholder8; Text000)
                        {
                            ApplicationArea = Jobs;
                            Visible = false;
                        }
                        field(ScheduleProfitLCYGLAcc; PL[3] - CL[3])
                        {
                            ApplicationArea = Jobs;
                            Caption = 'Budget Profit LCY (G/L Acc.)';
                            Editable = false;
                            ToolTip = 'Specifies budgeted profits for the job that are related to G/L accounts, expressed in the local currency.';

                            trigger OnDrillDown()
                            begin
                                JobCalcStatistics.ShowPlanningLine(3, true);
                            end;
                        }
                        field(UsageProfitLCYGLAcc; PL[7] - CL[7])
                        {
                            ApplicationArea = Jobs;
                            Caption = 'Usage Profit LCY (G/L Acc.)';
                            Editable = false;
                            ToolTip = 'Specifies usage profits for the job that are related to G/L accounts, expressed in the local currency.';

                            trigger OnDrillDown()
                            begin
                                JobCalcStatistics.ShowLedgEntry(3, true);
                            end;
                        }
                        field(ContractProfitLCYGLAcc; PL[11] - CL[11])
                        {
                            ApplicationArea = Jobs;
                            Caption = 'Billable Profit LCY (G/L Acc.)';
                            Editable = false;
                            ToolTip = 'Specifies billable profits for the job that are related to G/L accounts, expressed in the local currency.';

                            trigger OnDrillDown()
                            begin
                                JobCalcStatistics.ShowPlanningLine(3, false);
                            end;
                        }
                        field(InvoicedProfitLCYGLAcc; PL[15] - CL[15])
                        {
                            ApplicationArea = Jobs;
                            Caption = 'Invoiced Profit LCY (G/L Acc.)';
                            Editable = false;
                            ToolTip = 'Specifies invoiced profits for the job that are related to G/L accounts, expressed in the local currency.';

                            trigger OnDrillDown()
                            begin
                                JobCalcStatistics.ShowLedgEntry(3, false);
                            end;
                        }
                    }
                    group(Total)
                    {
                        Caption = 'Total';
                        field(Placeholder9; Text000)
                        {
                            ApplicationArea = Jobs;
                            Visible = false;
                        }
                        field(SchedulePriceLCYTotal; PL[4])
                        {
                            ApplicationArea = Jobs;
                            Caption = 'Budget Price LCY (Total)';
                            Editable = false;
                            ToolTip = 'Specifies all budgeted prices for the job, expressed in the local currency.';

                            trigger OnDrillDown()
                            begin
                                JobCalcStatistics.ShowPlanningLine(0, true);
                            end;
                        }
                        field(UsagePriceLCYTotal; PL[8])
                        {
                            ApplicationArea = Jobs;
                            Caption = 'Usage Price LCY (Total)';
                            Editable = false;
                            ToolTip = 'Specifies all usage prices for the job, expressed in the local currency.';

                            trigger OnDrillDown()
                            begin
                                JobCalcStatistics.ShowLedgEntry(0, true);
                            end;
                        }
                        field(ContractPriceLCYTotal; PL[12])
                        {
                            ApplicationArea = Jobs;
                            Caption = 'Billable Price LCY (Total)';
                            Editable = false;
                            ToolTip = 'Specifies all billable prices for the job, expressed in the local currency.';

                            trigger OnDrillDown()
                            begin
                                JobCalcStatistics.ShowPlanningLine(0, false);
                            end;
                        }
                        field(InvoicedPriceLCYTotal; PL[16])
                        {
                            ApplicationArea = Jobs;
                            Caption = 'Invoiced Price LCY (Total)';
                            Editable = false;
                            ToolTip = 'Specifies all invoiced prices for the job, expressed in the local currency.';

                            trigger OnDrillDown()
                            begin
                                JobCalcStatistics.ShowLedgEntry(0, false);
                            end;
                        }
                        field(Placeholder10; Text000)
                        {
                            ApplicationArea = Jobs;
                            Visible = false;
                        }
                        field(ScheduleCostLCYTotal; CL[4])
                        {
                            ApplicationArea = Jobs;
                            Caption = 'Budget Cost LCY (Total)';
                            Editable = false;
                            ToolTip = 'Specifies all budgeted costs for the job, expressed in the local currency.';

                            trigger OnDrillDown()
                            begin
                                JobCalcStatistics.ShowPlanningLine(0, true);
                            end;
                        }
                        field(UsageCostLCYTotal; CL[8])
                        {
                            ApplicationArea = Jobs;
                            Caption = 'Usage Cost LCY (Total)';
                            Editable = false;
                            ToolTip = 'Specifies all usage costs for the job, expressed in the local currency.';

                            trigger OnDrillDown()
                            begin
                                JobCalcStatistics.ShowLedgEntry(0, true);
                            end;
                        }
                        field(ContractCostLCYTotal; CL[12])
                        {
                            ApplicationArea = Jobs;
                            Caption = 'Billable Cost LCY (Total)';
                            Editable = false;
                            ToolTip = 'Specifies all billable costs for the job, expressed in the local currency.';

                            trigger OnDrillDown()
                            begin
                                JobCalcStatistics.ShowPlanningLine(0, false);
                            end;
                        }
                        field(InvoicedCostLCYTotal; CL[16])
                        {
                            ApplicationArea = Jobs;
                            Caption = 'Invoiced Cost LCY (Total)';
                            Editable = false;
                            ToolTip = 'Specifies all invoiced costs for the job, expressed in the local currency.';

                            trigger OnDrillDown()
                            begin
                                JobCalcStatistics.ShowLedgEntry(0, false);
                            end;
                        }
                        field(placeholer11; Text000)
                        {
                            ApplicationArea = Jobs;
                            Visible = false;
                        }
                        field(ScheduleProfitLCYTotal; PL[4] - CL[4])
                        {
                            ApplicationArea = Jobs;
                            Caption = 'Budget Profit LCY (Total)';
                            Editable = false;
                            ToolTip = 'Specifies all budgeted profits for the job, expressed in the local currency.';

                            trigger OnDrillDown()
                            begin
                                JobCalcStatistics.ShowPlanningLine(0, true);
                            end;
                        }
                        field(UsageProfitLCYTotal; PL[8] - CL[8])
                        {
                            ApplicationArea = Jobs;
                            Caption = 'Usage Profit LCY (Total)';
                            Editable = false;
                            ToolTip = 'Specifies all usage profits for the job, expressed in the local currency.';

                            trigger OnDrillDown()
                            begin
                                JobCalcStatistics.ShowLedgEntry(0, true);
                            end;
                        }
                        field(ContractProfitLCYTotal; PL[12] - CL[12])
                        {
                            ApplicationArea = Jobs;
                            Caption = 'Billable Profit LCY (Total)';
                            Editable = false;
                            ToolTip = 'Specifies all billable profits for the job, expressed in the local currency.';

                            trigger OnDrillDown()
                            begin
                                JobCalcStatistics.ShowPlanningLine(0, false);
                            end;
                        }
                        field(InvoicedProfitLCYTotal; PL[16] - CL[16])
                        {
                            ApplicationArea = Jobs;
                            Caption = 'Invoiced Profit LCY (Total)';
                            Editable = false;
                            ToolTip = 'Specifies all invoiced profits for the job, expressed in the local currency.';

                            trigger OnDrillDown()
                            begin
                                JobCalcStatistics.ShowLedgEntry(0, false);
                            end;
                        }
                    }
                }
            }
            group(Currency)
            {
                Caption = 'Currency';
                fixed(Control1904230801)
                {
                    ShowCaption = false;
                    group(Control1903193001)
                    {
                        Caption = 'Resource';
                        field(Price; '')
                        {
                            ApplicationArea = Jobs;
                            Caption = 'Price';
                            ToolTip = 'Specifies the price amounts.';
                        }
                        field(SchedulePrice; P[1])
                        {
                            ApplicationArea = Jobs;
                            Caption = 'Budget';
                            Editable = false;
                            ToolTip = 'Specifies values for budgeted jobs.';

                            trigger OnDrillDown()
                            begin
                                JobCalcStatistics.ShowPlanningLine(1, true);
                            end;
                        }
                        field(UsagePrice; P[5])
                        {
                            ApplicationArea = Jobs;
                            Caption = 'Usage';
                            Editable = false;
                            ToolTip = 'Specifies values for job usage.';

                            trigger OnDrillDown()
                            begin
                                JobCalcStatistics.ShowLedgEntry(1, true);
                            end;
                        }
                        field(ContractPrice; P[9])
                        {
                            ApplicationArea = Jobs;
                            Caption = 'Billable';
                            Editable = false;
                            ToolTip = 'Specifies the billable amounts.';

                            trigger OnDrillDown()
                            begin
                                JobCalcStatistics.ShowPlanningLine(1, false);
                            end;
                        }
                        field(InvoicedPrice; P[13])
                        {
                            ApplicationArea = Jobs;
                            Caption = 'Invoiced';
                            Editable = false;
                            ToolTip = 'Specifies values for invoiced jobs.';

                            trigger OnDrillDown()
                            begin
                                JobCalcStatistics.ShowLedgEntry(1, false);
                            end;
                        }
                        field(Cost; '')
                        {
                            ApplicationArea = Jobs;
                            Caption = 'Cost';
                            ToolTip = 'Specifies the cost amounts.';
                        }
                        field(ScheduleCost; C[1])
                        {
                            ApplicationArea = Jobs;
                            Caption = 'Budget';
                            Editable = false;
                            ToolTip = 'Specifies values for budgeted jobs.';

                            trigger OnDrillDown()
                            begin
                                JobCalcStatistics.ShowPlanningLine(1, true);
                            end;
                        }
                        field(UsageCost; C[5])
                        {
                            ApplicationArea = Jobs;
                            Caption = 'Usage';
                            Editable = false;
                            ToolTip = 'Specifies values for job usage.';

                            trigger OnDrillDown()
                            begin
                                JobCalcStatistics.ShowLedgEntry(1, true);
                            end;
                        }
                        field(ContractCost; C[9])
                        {
                            ApplicationArea = Jobs;
                            Caption = 'Billable';
                            Editable = false;
                            ToolTip = 'Specifies the billable amounts.';

                            trigger OnDrillDown()
                            begin
                                JobCalcStatistics.ShowPlanningLine(1, false);
                            end;
                        }
                        field(InvoicedCost; C[13])
                        {
                            ApplicationArea = Jobs;
                            Caption = 'Invoiced';
                            Editable = false;
                            ToolTip = 'Specifies values for invoiced jobs.';

                            trigger OnDrillDown()
                            begin
                                JobCalcStatistics.ShowLedgEntry(1, false);
                            end;
                        }
                        field(Profit; '')
                        {
                            ApplicationArea = Jobs;
                            Caption = 'Profit';
                            ToolTip = 'Specifies the profit amounts.';
                        }
                        field(ScheduleProfit; P[1] - C[1])
                        {
                            ApplicationArea = Jobs;
                            Caption = 'Budget';
                            Editable = false;
                            ToolTip = 'Specifies values for budgeted jobs.';

                            trigger OnDrillDown()
                            begin
                                JobCalcStatistics.ShowPlanningLine(1, true);
                            end;
                        }
                        field(UsageProfit; P[5] - C[5])
                        {
                            ApplicationArea = Jobs;
                            Caption = 'Usage';
                            Editable = false;
                            ToolTip = 'Specifies values for job usage.';

                            trigger OnDrillDown()
                            begin
                                JobCalcStatistics.ShowLedgEntry(1, true);
                            end;
                        }
                        field(ContractProfit; P[9] - C[9])
                        {
                            ApplicationArea = Jobs;
                            Caption = 'Billable';
                            Editable = false;
                            ToolTip = 'Specifies the billable amounts.';

                            trigger OnDrillDown()
                            begin
                                JobCalcStatistics.ShowPlanningLine(1, false);
                            end;
                        }
                        field(InvoicedProfit; P[13] - C[13])
                        {
                            ApplicationArea = Jobs;
                            Caption = 'Invoiced';
                            Editable = false;
                            ToolTip = 'Specifies values for invoiced jobs.';

                            trigger OnDrillDown()
                            begin
                                JobCalcStatistics.ShowLedgEntry(1, false);
                            end;
                        }
                    }
                    group(Control1904522201)
                    {
                        Caption = 'Item';
                        field(Placeholder12; Text000)
                        {
                            ApplicationArea = Jobs;
                            Visible = false;
                        }
                        field(SchedulePriceItem; P[2])
                        {
                            ApplicationArea = Jobs;
                            Caption = 'Budget Price (Item)';
                            Editable = false;
                            ToolTip = 'Specifies budgeted prices for the job that are related to items.';

                            trigger OnDrillDown()
                            begin
                                JobCalcStatistics.ShowPlanningLine(2, true);
                            end;
                        }
                        field(UsagePriceItem; P[6])
                        {
                            ApplicationArea = Jobs;
                            Caption = 'Usage Price (Item)';
                            Editable = false;
                            ToolTip = 'Specifies usage prices for the job that are related to items.';

                            trigger OnDrillDown()
                            begin
                                JobCalcStatistics.ShowLedgEntry(2, true);
                            end;
                        }
                        field(ContractPriceItem; P[10])
                        {
                            ApplicationArea = Jobs;
                            Caption = 'Billable Price (Item)';
                            Editable = false;
                            ToolTip = 'Specifies billable prices for the job that are related to items.';

                            trigger OnDrillDown()
                            begin
                                JobCalcStatistics.ShowPlanningLine(2, false);
                            end;
                        }
                        field(InvoicedPriceItem; P[14])
                        {
                            ApplicationArea = Jobs;
                            Caption = 'Invoiced Price (Item)';
                            Editable = false;
                            ToolTip = 'Specifies invoiced prices for the job that are related to items.';

                            trigger OnDrillDown()
                            begin
                                JobCalcStatistics.ShowLedgEntry(2, false);
                            end;
                        }
                        field(Placeholder13; Text000)
                        {
                            ApplicationArea = Jobs;
                            Visible = false;
                        }
                        field(ScheduleCostItem; C[2])
                        {
                            ApplicationArea = Jobs;
                            Caption = 'Budget Cost (Item)';
                            Editable = false;
                            ToolTip = 'Specifies budgeted costs for the job that are related to items.';

                            trigger OnDrillDown()
                            begin
                                JobCalcStatistics.ShowPlanningLine(2, true);
                            end;
                        }
                        field(UsageCostItem; C[6])
                        {
                            ApplicationArea = Jobs;
                            Caption = 'Usage Cost (Item)';
                            Editable = false;
                            ToolTip = 'Specifies usage costs for the job that are related to items.';

                            trigger OnDrillDown()
                            begin
                                JobCalcStatistics.ShowLedgEntry(2, true);
                            end;
                        }
                        field(ContractCostItem; C[10])
                        {
                            ApplicationArea = Jobs;
                            Caption = 'Billable Cost (Item)';
                            Editable = false;
                            ToolTip = 'Specifies billable costs for the job that are related to items.';

                            trigger OnDrillDown()
                            begin
                                JobCalcStatistics.ShowPlanningLine(2, false);
                            end;
                        }
                        field(InvoicedCostItem; C[14])
                        {
                            ApplicationArea = Jobs;
                            Caption = 'Invoiced Cost (Item)';
                            Editable = false;
                            ToolTip = 'Specifies invoiced costs for the job that are related to items.';

                            trigger OnDrillDown()
                            begin
                                JobCalcStatistics.ShowLedgEntry(2, false);
                            end;
                        }
                        field(Placeholder14; Text000)
                        {
                            ApplicationArea = Jobs;
                            Visible = false;
                        }
                        field(ScheduleProfitItem; P[2] - C[2])
                        {
                            ApplicationArea = Jobs;
                            Caption = 'Budget Profit (Item)';
                            Editable = false;
                            ToolTip = 'Specifies budgeted profits for the job that are related to items.';

                            trigger OnDrillDown()
                            begin
                                JobCalcStatistics.ShowPlanningLine(2, true);
                            end;
                        }
                        field(UsageProfitItem; P[6] - C[6])
                        {
                            ApplicationArea = Jobs;
                            Caption = 'Usage Profit (Item)';
                            Editable = false;
                            ToolTip = 'Specifies usage profits for the job that are related to items.';

                            trigger OnDrillDown()
                            begin
                                JobCalcStatistics.ShowLedgEntry(2, true);
                            end;
                        }
                        field(ContractProfitItem; P[10] - C[10])
                        {
                            ApplicationArea = Jobs;
                            Caption = 'Billable Profit (Item)';
                            Editable = false;
                            ToolTip = 'Specifies billable profits for the job that are related to items.';

                            trigger OnDrillDown()
                            begin
                                JobCalcStatistics.ShowPlanningLine(2, false);
                            end;
                        }
                        field(InvoicedProfitItem; P[14] - C[14])
                        {
                            ApplicationArea = Jobs;
                            Caption = 'Invoiced Profit (Item)';
                            Editable = false;
                            ToolTip = 'Specifies invoiced profits for the job that are related to items.';

                            trigger OnDrillDown()
                            begin
                                JobCalcStatistics.ShowLedgEntry(2, false);
                            end;
                        }
                    }
                    group(Control1904320401)
                    {
                        Caption = 'G/L Account';
                        field(Placeholder15; Text000)
                        {
                            ApplicationArea = Jobs;
                            Visible = false;
                        }
                        field(SchedulePriceGLAcc; P[3])
                        {
                            ApplicationArea = Jobs;
                            Caption = 'Budget Price (G/L Acc.)';
                            Editable = false;
                            ToolTip = 'Specifies budgeted prices for the job that are related to G/L accounts.';

                            trigger OnDrillDown()
                            begin
                                JobCalcStatistics.ShowPlanningLine(3, true);
                            end;
                        }
                        field(UsagePriceGLAcc; P[7])
                        {
                            ApplicationArea = Jobs;
                            Caption = 'Usage Price (G/L Acc.)';
                            Editable = false;
                            ToolTip = 'Specifies usage prices for the job that are related to G/L accounts.';

                            trigger OnDrillDown()
                            begin
                                JobCalcStatistics.ShowLedgEntry(3, true);
                            end;
                        }
                        field(ContractPriceGLAcc; P[11])
                        {
                            ApplicationArea = Jobs;
                            Caption = 'Billable Price (G/L Acc.)';
                            Editable = false;
                            ToolTip = 'Specifies billable prices for the job that are related to G/L accounts.';

                            trigger OnDrillDown()
                            begin
                                JobCalcStatistics.ShowPlanningLine(3, false);
                            end;
                        }
                        field(InvoicedPriceGLAcc; P[15])
                        {
                            ApplicationArea = Jobs;
                            Caption = 'Invoiced Price (G/L Acc.)';
                            Editable = false;
                            ToolTip = 'Specifies invoiced prices for the job that are related to G/L accounts.';

                            trigger OnDrillDown()
                            begin
                                JobCalcStatistics.ShowLedgEntry(3, false);
                            end;
                        }
                        field(Placeholder16; Text000)
                        {
                            ApplicationArea = Jobs;
                            Visible = false;
                        }
                        field(ScheduleCostGLAcc; C[3])
                        {
                            ApplicationArea = Jobs;
                            Caption = 'Budget Cost (G/L Acc.)';
                            Editable = false;
                            ToolTip = 'Specifies budgeted costs for the job that are related to G/L accounts.';

                            trigger OnDrillDown()
                            begin
                                JobCalcStatistics.ShowPlanningLine(3, true);
                            end;
                        }
                        field(UsageCostGLAcc; C[7])
                        {
                            ApplicationArea = Jobs;
                            Caption = 'Usage Cost (G/L Acc.)';
                            Editable = false;
                            ToolTip = 'Specifies usage costs for the job that are related to G/L accounts.';

                            trigger OnDrillDown()
                            begin
                                JobCalcStatistics.ShowLedgEntry(3, true);
                            end;
                        }
                        field(ContractCostGLAcc; C[11])
                        {
                            ApplicationArea = Jobs;
                            Caption = 'Billable Cost (G/L Acc.)';
                            Editable = false;
                            ToolTip = 'Specifies billable costs for the job that are related to G/L accounts.';

                            trigger OnDrillDown()
                            begin
                                JobCalcStatistics.ShowPlanningLine(3, false);
                            end;
                        }
                        field(InvoicedCostGLAcc; C[15])
                        {
                            ApplicationArea = Jobs;
                            Caption = 'Invoiced Cost (G/L Acc.)';
                            Editable = false;
                            ToolTip = 'Specifies invoiced costs for the job that are related to G/L accounts.';

                            trigger OnDrillDown()
                            begin
                                JobCalcStatistics.ShowLedgEntry(3, false);
                            end;
                        }
                        field(Placerholder17; Text000)
                        {
                            ApplicationArea = Jobs;
                            Visible = false;
                        }
                        field(ScheduleProfitGLAcc; P[3] - C[3])
                        {
                            ApplicationArea = Jobs;
                            Caption = 'Budget Profit (G/L Acc.)';
                            Editable = false;
                            ToolTip = 'Specifies budgeted profits for the job that are related to G/L accounts.';

                            trigger OnDrillDown()
                            begin
                                JobCalcStatistics.ShowPlanningLine(3, true);
                            end;
                        }
                        field(UsageProfitGLAcc; P[7] - C[7])
                        {
                            ApplicationArea = Jobs;
                            Caption = 'Usage Profit (G/L Acc.)';
                            Editable = false;
                            ToolTip = 'Specifies usage profits for the job that are related to G/L accounts.';

                            trigger OnDrillDown()
                            begin
                                JobCalcStatistics.ShowLedgEntry(3, true);
                            end;
                        }
                        field(ContractProfitGLAcc; P[11] - C[11])
                        {
                            ApplicationArea = Jobs;
                            Caption = 'Billable Profit (G/L Acc.)';
                            Editable = false;
                            ToolTip = 'Specifies billable profits for the job that are related to G/L accounts.';

                            trigger OnDrillDown()
                            begin
                                JobCalcStatistics.ShowPlanningLine(3, false);
                            end;
                        }
                        field(InvoicedProfitGLAcc; P[15] - C[15])
                        {
                            ApplicationArea = Jobs;
                            Caption = 'Invoiced Profit (G/L Acc.)';
                            Editable = false;
                            ToolTip = 'Specifies invoiced profits for the job that are related to G/L accounts.';

                            trigger OnDrillDown()
                            begin
                                JobCalcStatistics.ShowLedgEntry(3, false);
                            end;
                        }
                    }
                    group(Control1905314101)
                    {
                        Caption = 'Total';
                        field(Placeholder18; Text000)
                        {
                            ApplicationArea = Jobs;
                            Visible = false;
                        }
                        field(SchedulePriceTotal; P[4])
                        {
                            ApplicationArea = Jobs;
                            Caption = 'Budget Price (Total)';
                            Editable = false;
                            ToolTip = 'Specifies all budgeted prices for the job.';

                            trigger OnDrillDown()
                            begin
                                JobCalcStatistics.ShowPlanningLine(0, true);
                            end;
                        }
                        field(UsagePriceTotal; P[8])
                        {
                            ApplicationArea = Jobs;
                            Caption = 'Usage Price (Total)';
                            Editable = false;
                            ToolTip = 'Specifies all usage prices for the job.';

                            trigger OnDrillDown()
                            begin
                                JobCalcStatistics.ShowLedgEntry(0, true);
                            end;
                        }
                        field(ContractPriceTotal; P[12])
                        {
                            ApplicationArea = Jobs;
                            Caption = 'Billable Price (Total)';
                            Editable = false;
                            ToolTip = 'Specifies all billable prices for the task.';

                            trigger OnDrillDown()
                            begin
                                JobCalcStatistics.ShowPlanningLine(0, false);
                            end;
                        }
                        field(InvoicedPriceTotal; P[16])
                        {
                            ApplicationArea = Jobs;
                            Caption = 'Invoiced Price (Total)';
                            Editable = false;
                            ToolTip = 'Specifies all invoiced prices for the job.';

                            trigger OnDrillDown()
                            begin
                                JobCalcStatistics.ShowLedgEntry(0, false);
                            end;
                        }
                        field(Placeholder19; Text000)
                        {
                            ApplicationArea = Jobs;
                            Visible = false;
                        }
                        field(ScheduleCostTotal; C[4])
                        {
                            ApplicationArea = Jobs;
                            Caption = 'Budget Cost (Total)';
                            Editable = false;
                            ToolTip = 'Specifies all budgeted costs for the job.';

                            trigger OnDrillDown()
                            begin
                                JobCalcStatistics.ShowPlanningLine(0, true);
                            end;
                        }
                        field(UsageCostTotal; C[8])
                        {
                            ApplicationArea = Jobs;
                            Caption = 'Usage Cost (Total)';
                            Editable = false;
                            ToolTip = 'Specifies all usage costs for the job.';

                            trigger OnDrillDown()
                            begin
                                JobCalcStatistics.ShowLedgEntry(0, true);
                            end;
                        }
                        field(ContractCostTotal; C[12])
                        {
                            ApplicationArea = Jobs;
                            Caption = 'Billable Cost (Total)';
                            Editable = false;
                            ToolTip = 'Specifies all billable costs for the job.';

                            trigger OnDrillDown()
                            begin
                                JobCalcStatistics.ShowPlanningLine(0, false);
                            end;
                        }
                        field(InvoicedCostTotal; C[16])
                        {
                            ApplicationArea = Jobs;
                            Caption = 'Invoiced Cost (Total)';
                            Editable = false;
                            ToolTip = 'Specifies all invoiced costs for the job.';

                            trigger OnDrillDown()
                            begin
                                JobCalcStatistics.ShowLedgEntry(0, false);
                            end;
                        }
                        field(Placeholder20; Text000)
                        {
                            ApplicationArea = Jobs;
                            Visible = false;
                        }
                        field(ScheduleProfitTotal; P[4] - C[4])
                        {
                            ApplicationArea = Jobs;
                            Caption = 'Budget Profit (Total)';
                            Editable = false;
                            ToolTip = 'Specifies all budgeted profits for the job.';

                            trigger OnDrillDown()
                            begin
                                JobCalcStatistics.ShowPlanningLine(0, true);
                            end;
                        }
                        field(UsageProfitTotal; P[8] - C[8])
                        {
                            ApplicationArea = Jobs;
                            Caption = 'Usage Profit (Total)';
                            Editable = false;
                            ToolTip = 'Specifies all usage profits for the job.';

                            trigger OnDrillDown()
                            begin
                                JobCalcStatistics.ShowLedgEntry(0, true);
                            end;
                        }
                        field(ContractProfitTotal; P[12] - C[12])
                        {
                            ApplicationArea = Jobs;
                            Caption = 'Billable Profit (Total)';
                            Editable = false;
                            ToolTip = 'Specifies all billable profits for the job.';

                            trigger OnDrillDown()
                            begin
                                JobCalcStatistics.ShowPlanningLine(0, false);
                            end;
                        }
                        field(InvoicedProfitTotal; P[16] - C[16])
                        {
                            ApplicationArea = Jobs;
                            Caption = 'Invoiced Profit (Total)';
                            Editable = false;
                            ToolTip = 'Specifies all invoiced profits for the job.';

                            trigger OnDrillDown()
                            begin
                                JobCalcStatistics.ShowLedgEntry(0, false);
                            end;
                        }
                    }
                }
            }
            group("Job Planning Lines")
            {
                Caption = 'Job Planning Lines';

                field("Reserved From Stock"; Rec.GetQtyReservedFromStockState())
                {
                    ApplicationArea = Reservation;
                    Editable = false;
                    Caption = 'Reserved from stock';
                    ToolTip = 'Specifies what part of the job planning lines is reserved from inventory.';
                }                
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetCurrRecord()
    begin
        Clear(JobCalcStatistics);
        JobCalcStatistics.JobCalculateCommonFilters(Rec);
        JobCalcStatistics.CalculateAmounts();
        JobCalcStatistics.GetLCYCostAmounts(CL);
        JobCalcStatistics.GetLCYPriceAmounts(PL);
        JobCalcStatistics.GetCostAmounts(C);
        JobCalcStatistics.GetPriceAmounts(P);
    end;

    var
        JobCalcStatistics: Codeunit "Job Calculate Statistics";
        Text000: Label 'Placeholder';

    protected var
        CL: array[16] of Decimal;
        PL: array[16] of Decimal;
        P: array[16] of Decimal;
        C: array[16] of Decimal;
}

