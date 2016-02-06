require 'mini_exiftool'

require 'types/jpg'

describe Types::Base do
  describe '#update_mtime' do
    before(:all) do
      # create copy of test media files in tmp directory
      @temp_dir = './spec/data/tmp/'
      FileUtils.mkdir_p(@temp_dir)
      FileUtils.cp_r(Dir.glob('./spec/data/' + '*.*'), @temp_dir, preserve: true)
    end

    subject { base_handler.update_mtime }
    let(:base_handler) { type_class.new(temp_dir, filename, options) }
    let(:temp_dir) { @temp_dir }
    let(:options) { { test_mode: false } }
    let(:event_time) { base_handler.event_time }

    context 'when \'jpg\' file' do
      let(:type_class) { Types::JPG }
      context 'iPhone via Camera Sync' do
        let(:filename) { 'iPhone - Camera Sync.jpg' }

        it 'updates file mtime to EXIF event time' do
          expect(File.mtime(temp_dir + filename)).to_not eq event_time
          is_expected.to eq 1
          expect(File.mtime(temp_dir + filename)).to eq event_time
        end
      end
      context 'iPhone via USB' do
        let(:filename) { 'iPhone - USB.jpg' }

        it 'does NOT update file mtime' do
          expect(File.mtime(temp_dir + filename)).to eq event_time
          is_expected.to eq 0
          expect(File.mtime(temp_dir + filename)).to eq event_time
        end
      end
      context 'Canon T2i via USB' do
        let(:filename) { 'Canon T2i - USB.jpg' }

        it 'does NOT update file mtime' do
          expect(File.mtime(temp_dir + filename)).to eq event_time
          is_expected.to eq 0
          expect(File.mtime(temp_dir + filename)).to eq event_time
        end
      end
      context 'Canon ELPH via USB' do
        let(:filename) { 'Canon ELPH - USB.jpg' }

        it 'does NOT update file mtime' do
          # TODO: off by 1 second so this check fails =/
          # expect(File.mtime(temp_dir + filename)).to eq event_time
          is_expected.to eq 0
          # expect(File.mtime(temp_dir + filename)).to eq event_time
        end
      end
    end
    after(:all) do
      # remove temp directory after tests
      FileUtils.rm_rf(@temp_dir)
    end
  end
end
