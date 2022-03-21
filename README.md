# OandaService

An API service to handle intensive processing that shouldn't be handled by the [Oanda Worker](https://github.com/kobusjoubert/oanda_worker) app on each strategy run.

The idea is to prosess complex and long running scripts here so that it is ready to be consumed by other applications.

## Usage

Create Google Sheets where the Point and Figure points will be plotted against if you want to visually inspect the points. Then update the `INSTRUMENTS` constant and add the Google Sheet IDs there. You will also need to set the `GOOGLE_CLIENT_EMAIL` and `GOOGLE_PRIVATE_KEY` environment variables to be able to plot to Google Sheets.

### Development

Start the service

    bin/rails s

Start the workers

    WORKERS=IndicatorUpdateJob bundle exec rake sneakers:run

### Backtesting

Start the service

    RAILS_ENV=backtest bin/rails s --pid `pwd`/tmp/pids/server_backtest.pid

Start the workers

    RAILS_ENV=backtest WORKERS=IndicatorUpdateJob bundle exec rake sneakers:run

## Examples

### Welcome

    curl -i -XGET 'http://localhost:3100/public/welcome' -H 'Content-Type: application/json' -H 'X-User-Email: oanda_trader@translate3d.com' -H 'X-User-Token: TFq61Z7tP6A3Y18Lzz2j'
    curl -i -XGET 'http://localhost:3100/public/welcome' -H 'Content-Type: application/json' -H 'X-User-Email: oanda_worker@translate3d.com' -H 'X-User-Token: QcABSZSGdhGC5FcxPUrL'

### Request Point & Figure

Call the API endpoint to pull the latest plotted points for a given instrument.

    curl -i -XGET 'http://localhost:3100/indicators/point_and_figure?instrument=EUR_USD&granularity=H4&count=100' -H 'Content-Type: application/json' -H 'X-User-Email: oanda_worker@translate3d.com' -H 'X-User-Token: QcABSZSGdhGC5FcxPUrL'

The Point and Figure indicator updates every minute and plots new points to a Google Sheet for visual inspection. Use [Oanda Clock](https://github.com/kobusjoubert/oanda_clock) to change the update frequency.

![point-and-figure](https://user-images.githubusercontent.com/3071529/159260763-b1a0eec6-d9f0-45a3-a51c-d7591f8507f5.png)

## Service Ideas

* Indicators

* News

* Predictions

* Candles

## Developer Setup

Create the database

```ruby
bin/rails db:create
RAILS_ENV=backtest bin/rails db:create
```

Migrate the database

```ruby
bin/rails db:migrate
RAILS_ENV=backtest bin/rails db:migrate
```

Setup the database with the required authenticated users

```ruby
bin/rails db:seed
RAILS_ENV=backtest bin/rails db:seed
```
