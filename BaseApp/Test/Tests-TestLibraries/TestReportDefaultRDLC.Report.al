report 134601 "Test Report - Default=RDLC"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Test Report - Default=RDLC.rdlc';
    WordLayout = './Test Report - Default=RDLC.docx';

    dataset
    {
        dataitem(Customer; Customer)
        {
            column(No; "No.")
            {
                IncludeCaption = true;
            }
            column(Name; Name)
            {
                IncludeCaption = true;
            }
        }
    }

    requestpage
    {

        layout
        {
        }

        actions
        {
        }
    }

    labels
    {
    }
}

