namespace :db do
  # bin/rake "db:clear_all_indicators[PointAndFigure]"
  desc 'Destroy all indicator records'
  task :clear_all_indicators, [:indicator_name] => [:environment] do |task, args|
    Object.const_get("Indicators::#{args.indicator_name}").destroy_all
    p "All Indicators::#{args.indicator_name} records destroyed!"
  end

  # bin/rake "db:clear_old_indicators[PointAndFigure, 1000]"
  desc 'Destroy old indicator records'
  task :clear_old_indicators, [:indicator_name, :keep] => [:environment] do |task, args|
    today = Time.now.utc

    unless today.sunday?
      printf "Will delete points on Sunday only to prevent any interference with the update processes during the week :) Today is week day #{today.wday}!\n"
      next
    end

    max_records_to_keep = args.keep.to_i
    indicator_class     = Object.const_get("Indicators::#{args.indicator_name}")

    indicator_class.select(:instrument, :granularity, :box_size, :reversal_amount, :high_low_close).distinct.each do |indicator|
      attributes        = indicator.attributes.except('id')
      relation          = indicator_class.where(attributes)
      records_to_delete = relation.count - max_records_to_keep

      if records_to_delete > 0
        records_deleted = relation.order(id: :asc).limit(records_to_delete).destroy_all
        printf "#{records_deleted.size} old Indicators::#{args.indicator_name} #{attributes} records destroyed!"
      else
        printf "No old Indicators::#{args.indicator_name} #{attributes} records to destroy!"
      end

      printf "\n"
    end
  end
end
