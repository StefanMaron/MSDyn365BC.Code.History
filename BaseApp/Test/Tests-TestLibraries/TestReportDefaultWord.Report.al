report 134600 "Test Report - Default=Word"
{
    RDLCLayout = './Test Report - Default=Word.rdlc';
    WordLayout = './Test Report - Default=Word.docx';
    DefaultLayout = Word;

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

