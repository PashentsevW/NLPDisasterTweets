#!/bin/bash

source /opt/miniconda3/bin/activate base

cd ${containerWorkspaceFolder} \
    && kaggle competitions download -c nlp-getting-started -p data/ \
    && cd data \
    && unzip nlp-getting-started.zip \
    && rm -f nlp-getting-started.zip

python -c "import nltk; nltk.download('averaged_perceptron_tagger')"
python -c "import nltk; nltk.download('punkt')"
python -c "import nltk; nltk.download('tagsets')"
