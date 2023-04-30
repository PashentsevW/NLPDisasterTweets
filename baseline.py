import os

import catboost
import numpy
import pandas

import constants

_ARTIFACTS_PATH = constants.ARTIFATCS_PATH / 'baseline'


def prepare_data(data_df: pandas.DataFrame, train: bool = True) -> catboost.Pool:
    data = (data_df
            .drop(columns=['location'])
            .loc[:, ['id', 'keyword', 'text']]
            .fillna('NA')
            .to_numpy())
    return catboost.Pool(data=data,
                         label=data_df['target'].to_numpy() if train else None,
                         cat_features=['keyword'],
                         text_features=['text'],
                         feature_names=['id', 'keyword', 'text'])


def main() -> None:
    if not _ARTIFACTS_PATH.exists():
        _ARTIFACTS_PATH.mkdir(parents=True, exist_ok=True)
    else:
        os.system(f'rm -fr {_ARTIFACTS_PATH}/*')

    train_df = pandas.read_csv(constants.DATA_PATH / 'train.csv')
    test_df = pandas.read_csv(constants.DATA_PATH / 'test.csv')

    train_pool, test_pool = (prepare_data(train_df),
                             prepare_data(test_df, False))

    params = {'loss_function': 'Logloss',
              'eval_metric': 'F1',
              'iterations': 10_000,
              'learning_rate': 0.01,
              'random_seed': constants.RANDOM_SEED,
              'simple_ctr': 'BinarizedTargetMeanValue',
              'train_dir': str(_ARTIFACTS_PATH / 'train_info')}

    cv_results_df, cb_models = catboost.cv(pool=train_pool,
                                           params=params,
                                           fold_count=5,
                                           partition_random_seed=constants.RANDOM_SEED,
                                           shuffle=True,
                                           stratified=True,
                                           early_stopping_rounds=100,
                                           verbose=100,
                                           plot=False,
                                           return_models=True)

    cv_results_df.to_csv(_ARTIFACTS_PATH / 'cv_results.csv', index=False)

    predictions = numpy.full(shape=(test_pool.num_row(), len(cb_models)), fill_value=numpy.NaN)
    for i, cb_model in enumerate(cb_models):
        predictions[:, i] = cb_model.predict(test_pool, prediction_type='Probability')[:, 1]

        cb_model.save_model(_ARTIFACTS_PATH / f'model_{i}.cbm')

    submission_df = test_df.loc[:, ['id']]
    submission_df['target'] = (predictions.mean(axis=1) > 0.5).astype(int)

    submission_df.to_csv(_ARTIFACTS_PATH / 'submission.csv', index=False)


if __name__ == '__main__':
    main()
