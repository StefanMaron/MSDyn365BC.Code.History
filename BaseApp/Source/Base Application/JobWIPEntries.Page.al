page 1008 "Job WIP Entries"
{
    ApplicationArea = Jobs;
    Caption = 'Job WIP Entries';
    DataCaptionFields = "Job No.";
    Editable = false;
    PageType = List;
    SourceTable = "Job WIP Entry";
    UsageCategory = History;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("WIP Posting Date"; "WIP Posting Date")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the posting date you entered in the Posting Date field on the Options FastTab in the Job Calculate WIP batch job.';
                }
                field("Document No."; "Document No.")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the document number you entered in the Document No. field on the Options FastTab in the Job Calculate WIP batch job.';
                }
                field("Job No."; "Job No.")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the number of the related job.';
                }
                field("Job Complete"; "Job Complete")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies whether the Job WIP Entry was created for a job with a Completed status.';
                }
                field("Job WIP Total Entry No."; "Job WIP Total Entry No.")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the entry number of the WIP total.';
                }
                field("G/L Account No."; "G/L Account No.")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the general ledger account number to which the WIP on this entry will be posted, if you run the Job Post WIP to the general ledger batch job.';
                }
                field("G/L Bal. Account No."; "G/L Bal. Account No.")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the general ledger balancing account number that WIP on this entry will be posted to, if you run the Job Post WIP to general ledger batch job.';
                }
                field("WIP Method Used"; "WIP Method Used")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the WIP method that was specified for the job when you ran the Job Calculate WIP batch job.';
                }
                field("WIP Posting Method Used"; "WIP Posting Method Used")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the WIP posting method used. The information in this field comes from the setting you have specified on the job card.';
                }
                field(Type; Type)
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the WIP type for this entry.';
                }
                field("WIP Entry Amount"; "WIP Entry Amount")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the WIP amount that will be posted for this entry, if you run the Job Post WIP to G/L batch job.';
                }
                field("Job Posting Group"; "Job Posting Group")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the posting group related to this entry.';
                }
                field(Reverse; Reverse)
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies whether the entry has been part of a reverse transaction (correction) made by the reverse function.';
                }
                field("Global Dimension 1 Code"; "Global Dimension 1 Code")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies the code for the global dimension that is linked to the record or entry for analysis purposes. Two global dimensions, typically for the company''s most important activities, are available on all cards, documents, reports, and lists.';
                }
                field("Global Dimension 2 Code"; "Global Dimension 2 Code")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies the code for the global dimension that is linked to the record or entry for analysis purposes. Two global dimensions, typically for the company''s most important activities, are available on all cards, documents, reports, and lists.';
                }
                field("Entry No."; "Entry No.")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the number of the entry, as assigned from the specified number series when the entry was created.';
                }
                field("Dimension Set ID"; "Dimension Set ID")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies a reference to a combination of dimension values. The actual values are stored in the Dimension Set Entry table.';
                    Visible = false;
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
            group("Ent&ry")
            {
                Caption = 'Ent&ry';
                Image = Entry;
                action("<Action57>")
                {
                    ApplicationArea = Jobs;
                    Caption = 'WIP Totals';
                    Image = EntriesList;
                    Promoted = true;
                    PromotedCategory = Process;
                    RunObject = Page "Job WIP Totals";
                    RunPageLink = "Entry No." = FIELD("Job WIP Total Entry No.");
                    ToolTip = 'View the job''s WIP totals.';
                }
                action(Dimensions)
                {
                    AccessByPermission = TableData Dimension = R;
                    ApplicationArea = Dimensions;
                    Caption = 'Dimensions';
                    Image = Dimensions;
                    ShortCutKey = 'Alt+D';
                    ToolTip = 'View or edit dimensions, such as area, project, or department, that you can assign to sales and purchase documents to distribute costs and analyze transaction history.';

                    trigger OnAction()
                    begin
                        ShowDimensions;
                    end;
                }
                action(SetDimensionFilter)
                {
                    ApplicationArea = Dimensions;
                    Caption = 'Set Dimension Filter';
                    Ellipsis = true;
                    Image = "Filter";
                    ToolTip = 'Limit the entries according to the dimension filters that you specify. NOTE: If you use a high number of dimension combinations, this function may not work and can result in a message that the SQL server only supports a maximum of 2100 parameters.';

                    trigger OnAction()
                    begin
                        SetFilter("Dimension Set ID", DimensionSetIDFilter.LookupFilter);
                    end;
                }
            }
        }
    }

    var
        DimensionSetIDFilter: Page "Dimension Set ID Filter";
}

